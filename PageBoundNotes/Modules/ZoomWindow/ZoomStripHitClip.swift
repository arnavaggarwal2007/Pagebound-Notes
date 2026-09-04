import SwiftUI
import UIKit

/// Hosts the magnified zoom strip content in a fixed-size UIKit container so
/// `PKCanvasView` hits cannot escape into surrounding zoom chrome (mini preview, controls).
struct ZoomStripHitClip<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ZoomStripClipContainerView {
        let container = ZoomStripClipContainerView()
        container.clipsToBounds = true
        container.isMultipleTouchEnabled = true
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

    func updateUIView(_ uiView: ZoomStripClipContainerView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }

    final class Coordinator {
        var hostingController: UIHostingController<Content>?
    }
}

final class ZoomStripClipContainerView: UIView {
    weak var hostingView: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}
