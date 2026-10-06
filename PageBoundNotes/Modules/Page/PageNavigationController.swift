import Combine
import UIKit

/// Session-only page pinch, two-finger pan, and fit. Not persisted.
/// Does not publish zoom changes — publishing during pinch caused view-update storms.
@MainActor
final class PageNavigationController: ObservableObject {
    weak var scrollView: UIScrollView?
    private(set) var zoomWindowActive = false
    private(set) var pageSize: CGSize = .zero
    var padding: CGFloat = 24

    private var savedScale: CGFloat = 0
    private var lastFitScale: CGFloat = 0
    private var lastViewportSize: CGSize = .zero
    private var isAtFitScale = false
    private var viewportChangePending = false
    private var didApplyInitialFit = false
    private var isApplyingScale = false

    func attach(_ scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else { return }
        self.scrollView = scrollView
        didApplyInitialFit = false
    }

    func updatePageSize(_ size: CGSize) {
        guard size != pageSize else { return }
        pageSize = size
        if !zoomWindowActive {
            didApplyInitialFit = false
        }
    }

    func configureForCurrentBounds() {
        guard !isApplyingScale, let scrollView else { return }
        guard scrollView.bounds.width > 1, scrollView.bounds.height > 1 else { return }
        guard pageSize.width > 0, pageSize.height > 0 else { return }

        let viewport = scrollView.bounds.size
        let sizeChanged = viewportSizeChanged(from: lastViewportSize, to: viewport)

        if zoomWindowActive {
            if sizeChanged {
                viewportChangePending = true
                lastViewportSize = viewport
            }
            applyZoomWindowLock(on: scrollView)
            return
        }

        updateZoomRange(on: scrollView)
        if !didApplyInitialFit {
            didApplyInitialFit = true
            let fit = minimumScale(for: scrollView)
            let scale = savedScale > 0
                ? PageNavigationMath.clampedScale(savedScale, minimum: fit)
                : fit
            lastFitScale = fit
            isAtFitScale = abs(scale - fit) <= PageNavigationMath.fitMatchTolerance
            apply(scale: scale, on: scrollView, animated: false)
            savedScale = scale
            lastViewportSize = viewport
            viewportChangePending = false
            return
        }

        if sizeChanged || viewportChangePending {
            lastViewportSize = viewport
            viewportChangePending = false
            applyViewportChange(on: scrollView)
        }
    }

    func fitPage(animated: Bool = true) {
        guard !zoomWindowActive, let scrollView else { return }
        guard scrollView.bounds.width > 1, scrollView.bounds.height > 1 else { return }
        guard pageSize.width > 0, pageSize.height > 0 else { return }
        updateZoomRange(on: scrollView)
        let fit = minimumScale(for: scrollView)
        lastFitScale = fit
        isAtFitScale = true
        apply(scale: fit, on: scrollView, animated: animated)
        savedScale = fit
        didApplyInitialFit = true
        lastViewportSize = scrollView.bounds.size
    }

    func setZoomWindowActive(_ active: Bool) {
        guard let scrollView else {
            zoomWindowActive = active
            return
        }
        if active {
            if !zoomWindowActive, didApplyInitialFit {
                savedScale = scrollView.zoomScale
            }
            zoomWindowActive = true
            applyZoomWindowLock(on: scrollView)
        } else {
            zoomWindowActive = false
            updateZoomRange(on: scrollView)
            applyGesturePolicy(on: scrollView)
            let fit = minimumScale(for: scrollView)
            let restore = savedScale > 0 ? savedScale : fit
            apply(
                scale: PageNavigationMath.clampedScale(restore, minimum: fit),
                on: scrollView,
                animated: false
            )
        }
    }

    func rememberScale(_ scale: CGFloat) {
        guard !zoomWindowActive, !isApplyingScale else { return }
        savedScale = scale
        isAtFitScale = abs(scale - lastFitScale) <= PageNavigationMath.fitMatchTolerance
    }

    private func applyViewportChange(on scrollView: UIScrollView) {
        let newFit = minimumScale(for: scrollView)
        updateZoomRange(on: scrollView)
        let next = PageNavigationMath.scaleAfterViewportChange(
            currentScale: scrollView.zoomScale,
            newFitScale: newFit,
            isAtFit: isAtFitScale
        )
        lastFitScale = newFit
        if abs(scrollView.zoomScale - next) > PageNavigationMath.fitMatchTolerance {
            apply(scale: next, on: scrollView, animated: false)
        }
        savedScale = next
    }

    private func viewportSizeChanged(from previous: CGSize, to next: CGSize) -> Bool {
        abs(previous.width - next.width) > 0.5 || abs(previous.height - next.height) > 0.5
    }

    func centeringInsets(for scrollView: UIScrollView) -> PageNavigationInsets {
        PageNavigationMath.centeringInsets(
            contentSize: scrollView.contentSize,
            viewportSize: scrollView.bounds.size
        )
    }

    func revealContentPoint(_ point: CGPoint, bottomObstruction: CGFloat, animated: Bool) {
        guard let scrollView else { return }
        let scale = max(scrollView.zoomScale, 0.01)
        let visibleHeight = scrollView.bounds.height - bottomObstruction
        guard visibleHeight > 1 else { return }
        let targetY = point.y * scale
        let visibleBottom = scrollView.contentOffset.y + visibleHeight
        guard targetY > visibleBottom else { return }

        var offset = scrollView.contentOffset
        offset.y = targetY - visibleHeight
        let minY = -scrollView.adjustedContentInset.top
        let maxY = max(minY, scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom)
        offset.y = min(max(offset.y, minY), maxY)
        scrollView.setContentOffset(offset, animated: animated)
    }

    private func applyZoomWindowLock(on scrollView: UIScrollView) {
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 1
        applyGesturePolicy(on: scrollView)
        if abs(scrollView.zoomScale - 1) > 0.01 {
            apply(scale: 1, on: scrollView, animated: false)
        }
        scrollView.contentInset = .zero
    }

    private func updateZoomRange(on scrollView: UIScrollView) {
        let fit = minimumScale(for: scrollView)
        scrollView.minimumZoomScale = fit
        scrollView.maximumZoomScale = max(fit, PageNavigationMath.maximumScale)
    }

    private func minimumScale(for scrollView: UIScrollView) -> CGFloat {
        let fit = PageNavigationMath.fitScale(
            pageSize: pageSize,
            viewportSize: scrollView.bounds.size,
            padding: padding
        )
        return min(max(fit, 0.05), PageNavigationMath.maximumScale)
    }

    private func apply(scale: CGFloat, on scrollView: UIScrollView, animated: Bool) {
        isApplyingScale = true
        scrollView.setZoomScale(scale, animated: animated)
        let offset = PageNavigationMath.centeredOffset(
            pageSize: pageSize,
            viewportSize: scrollView.bounds.size,
            scale: scrollView.zoomScale,
            padding: padding
        )
        scrollView.setContentOffset(offset, animated: animated)
        let insets = centeringInsets(for: scrollView)
        scrollView.contentInset = UIEdgeInsets(
            top: insets.top,
            left: insets.left,
            bottom: insets.bottom,
            right: insets.right
        )
        isApplyingScale = false
    }

    private func applyGesturePolicy(on scrollView: UIScrollView) {
        let allow = !zoomWindowActive
        scrollView.pinchGestureRecognizer?.isEnabled = allow
        scrollView.panGestureRecognizer.isEnabled = allow
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 2
        scrollView.isScrollEnabled = allow
    }
}
