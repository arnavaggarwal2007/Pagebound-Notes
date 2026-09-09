import SwiftUI
import UIKit

/// Hosts the magnified zoom strip content in a fixed-size UIKit container so
/// `PKCanvasView` hits cannot escape into surrounding zoom chrome (mini preview, controls).
/// Also owns `UIPencilInteraction` so Apple Pencil double-tap works outside nested hosting.
struct ZoomStripHitClip<Content: View>: UIViewRepresentable {
    let content: Content
    var onPencilSwitchEraser: () -> Void
    var onPencilSwitchPrevious: () -> Void

    init(
        onPencilSwitchEraser: @escaping () -> Void,
        onPencilSwitchPrevious: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onPencilSwitchEraser = onPencilSwitchEraser
        self.onPencilSwitchPrevious = onPencilSwitchPrevious
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPencilSwitchEraser: onPencilSwitchEraser,
            onPencilSwitchPrevious: onPencilSwitchPrevious
        )
    }

    func makeUIView(context: Context) -> ZoomStripClipContainerView {
        let container = ZoomStripClipContainerView()
        container.clipsToBounds = true
        container.isMultipleTouchEnabled = true

        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = context.coordinator
        container.addInteraction(pencilInteraction)
        context.coordinator.pencilInteraction = pencilInteraction

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
        context.coordinator.onPencilSwitchEraser = onPencilSwitchEraser
        context.coordinator.onPencilSwitchPrevious = onPencilSwitchPrevious
        context.coordinator.hostingController?.rootView = content
    }

    final class Coordinator: NSObject, UIPencilInteractionDelegate {
        var hostingController: UIHostingController<Content>?
        weak var pencilInteraction: UIPencilInteraction?
        var onPencilSwitchEraser: () -> Void
        var onPencilSwitchPrevious: () -> Void

        init(
            onPencilSwitchEraser: @escaping () -> Void,
            onPencilSwitchPrevious: @escaping () -> Void
        ) {
            self.onPencilSwitchEraser = onPencilSwitchEraser
            self.onPencilSwitchPrevious = onPencilSwitchPrevious
        }

        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            let action = UIPencilInteraction.preferredTapAction
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch action {
                case .switchEraser:
                    self.onPencilSwitchEraser()
                case .switchPrevious:
                    self.onPencilSwitchPrevious()
                default:
                    break
                }
            }
        }
    }
}

final class ZoomStripClipContainerView: UIView {
    weak var hostingView: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else { return nil }
        return super.hitTest(point, with: event)
    }
}
