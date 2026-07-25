import SwiftUI
import UIKit

/// Hosts SwiftUI overlay content and forwards hits selectively so empty canvas regions
/// reach `PKCanvasView` below while objects, handles, and editors stay on the overlay.
struct PageHitPassthrough<Content: View>: UIViewRepresentable {
    let content: Content
    let claimsHit: (CGPoint) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> SelectivePassthroughContainerView {
        let container = SelectivePassthroughContainerView()
        container.claimsHit = claimsHit
        let hosting = UIHostingController(rootView: content)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        container.hostingView = hosting.view
        container.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.hostingController = hosting
        return container
    }

    func updateUIView(_ uiView: SelectivePassthroughContainerView, context: Context) {
        uiView.claimsHit = claimsHit
        context.coordinator.hostingController?.rootView = content
    }

    final class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

final class SelectivePassthroughContainerView: UIView {
    weak var hostingView: UIView?
    var claimsHit: ((CGPoint) -> Bool)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        if claimsHit?(point) == true {
            return super.hitTest(point, with: event)
        }
        return nil
    }
}
