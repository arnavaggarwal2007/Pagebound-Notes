import SwiftUI
import UIKit

/// Holds scroll-view keep-in-view state without publishing (avoids SwiftUI update storms).
@MainActor
final class PageScrollRuntime: ObservableObject {
    weak var scrollView: UIScrollView?
    var keepInViewTask: Task<Void, Never>?
    var lastMid: CGPoint?

    func attachScrollViewIfNeeded(_ scrollView: UIScrollView?) {
        guard let scrollView else { return }
        guard self.scrollView !== scrollView else { return }
        self.scrollView = scrollView
    }

    func clearLastMid() {
        lastMid = nil
    }
}

/// Resolves the hosting `UIScrollView` once so callers can `setContentOffset`
/// while SwiftUI `.scrollDisabled(true)` keeps user panning off.
struct PageScrollViewAccessor: UIViewRepresentable {
    let runtime: PageScrollRuntime
    var onResolved: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(runtime: runtime, onResolved: onResolved)
    }

    func makeUIView(context: Context) -> ScrollViewFinderView {
        let view = ScrollViewFinderView()
        view.onFound = { scrollView in
            context.coordinator.handleFound(scrollView)
        }
        return view
    }

    func updateUIView(_ uiView: ScrollViewFinderView, context: Context) {
        context.coordinator.runtime = runtime
        context.coordinator.onResolved = onResolved
        uiView.onFound = { scrollView in
            context.coordinator.handleFound(scrollView)
        }
        if runtime.scrollView == nil {
            uiView.findIfNeeded()
        }
    }

    final class Coordinator {
        var runtime: PageScrollRuntime
        var onResolved: (() -> Void)?

        init(runtime: PageScrollRuntime, onResolved: (() -> Void)?) {
            self.runtime = runtime
            self.onResolved = onResolved
        }

        @MainActor
        func handleFound(_ scrollView: UIScrollView?) {
            let previous = runtime.scrollView
            runtime.attachScrollViewIfNeeded(scrollView)
            if runtime.scrollView !== previous, runtime.scrollView != nil {
                onResolved?()
            }
        }
    }
}

final class ScrollViewFinderView: UIView {
    var onFound: ((UIScrollView?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        findIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        findIfNeeded()
    }

    func findIfNeeded() {
        onFound?(enclosingScrollView())
    }

    private func enclosingScrollView() -> UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}
