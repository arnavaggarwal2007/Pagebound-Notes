import SwiftUI
import UIKit

/// Outer page scroller. PencilKit stays at 1× inside the hosted page; this view owns pinch and two-finger pan.
struct PageCanvasScrollView<Content: View>: UIViewRepresentable {
    var contentPixelSize: CGSize
    var pageSize: CGSize
    var padding: CGFloat
    var zoomWindowActive: Bool
    var navigation: PageNavigationController
    var runtime: PageScrollRuntime
    var onReady: () -> Void
    var shouldFitOnDoubleTap: (CGPoint) -> Bool
    var content: Content

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PageNavigationScrollView {
        let scrollView = PageNavigationScrollView()
        scrollView.delegate = context.coordinator
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.panGestureRecognizer.minimumNumberOfTouches = 2
        scrollView.panGestureRecognizer.maximumNumberOfTouches = 2

        let doubleTapProxy = PageDoubleTapProxy()
        let doubleTap = UITapGestureRecognizer(target: doubleTapProxy, action: #selector(PageDoubleTapProxy.handle(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.cancelsTouchesInView = false
        doubleTap.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        doubleTapProxy.handler = { [weak coordinator = context.coordinator] gesture in
            coordinator?.handleDoubleTap(gesture)
        }
        scrollView.addGestureRecognizer(doubleTap)
        context.coordinator.doubleTapProxy = doubleTapProxy
        context.coordinator.doubleTap = doubleTap

        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = true
        host.safeAreaRegions = []
        host.sizingOptions = []
        scrollView.addSubview(host.view)
        context.coordinator.hostingController = host

        scrollView.onLayout = { [weak coordinator = context.coordinator] in
            coordinator?.navigation?.configureForCurrentBounds()
        }

        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ scrollView: PageNavigationScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.navigation = navigation
        coordinator.runtime = runtime
        coordinator.onReady = onReady
        coordinator.shouldFitOnDoubleTap = shouldFitOnDoubleTap
        coordinator.padding = padding
        coordinator.hostingController?.rootView = content

        navigation.updatePageSize(pageSize)
        navigation.padding = padding
        navigation.attach(scrollView)
        runtime.attachScrollViewIfNeeded(scrollView)

        if coordinator.contentPixelSize != contentPixelSize || abs(scrollView.zoomScale - 1) < 0.01 {
            coordinator.contentPixelSize = contentPixelSize
            coordinator.hostingController?.view.frame = CGRect(origin: .zero, size: contentPixelSize)
            if abs(scrollView.zoomScale - 1) < 0.01 {
                scrollView.contentSize = contentPixelSize
            }
        }

        let zoomChanged = coordinator.appliedZoomWindowActive != zoomWindowActive
        coordinator.appliedZoomWindowActive = zoomWindowActive
        if zoomChanged || !coordinator.didApplyZoomPolicy {
            coordinator.didApplyZoomPolicy = true
            navigation.setZoomWindowActive(zoomWindowActive)
        }
        coordinator.doubleTap?.isEnabled = !zoomWindowActive

        if !coordinator.didNotifyReady || (zoomWindowActive && zoomChanged) {
            coordinator.didNotifyReady = true
            onReady()
        }

        navigation.configureForCurrentBounds()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        var navigation: PageNavigationController?
        var runtime: PageScrollRuntime?
        var onReady: () -> Void = {}
        var shouldFitOnDoubleTap: (CGPoint) -> Bool = { _ in true }
        var padding: CGFloat = 0
        var contentPixelSize: CGSize = .zero
        var appliedZoomWindowActive = false
        var didApplyZoomPolicy = false
        var didNotifyReady = false
        var doubleTapProxy: PageDoubleTapProxy?
        var doubleTap: UITapGestureRecognizer?
        weak var scrollView: UIScrollView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let navigation else { return }
            let insets = navigation.centeringInsets(for: scrollView)
            scrollView.contentInset = UIEdgeInsets(
                top: insets.top,
                left: insets.left,
                bottom: insets.bottom,
                right: insets.right
            )
            navigation.rememberScale(scrollView.zoomScale)
            doubleTap?.isEnabled = !navigation.zoomWindowActive
        }

        func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let host = hostingController?.view else { return }
            guard navigation?.zoomWindowActive != true else { return }
            let point = gesture.location(in: host)
            guard shouldFitOnDoubleTap(point) else { return }
            navigation?.fitPage(animated: true)
        }
    }
}

/// Non-generic target so the double-tap recognizer can use `@objc` outside the generic representable.
final class PageDoubleTapProxy: NSObject {
    var handler: ((UITapGestureRecognizer) -> Void)?

    @objc func handle(_ gesture: UITapGestureRecognizer) {
        handler?(gesture)
    }
}

final class PageNavigationScrollView: UIScrollView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
