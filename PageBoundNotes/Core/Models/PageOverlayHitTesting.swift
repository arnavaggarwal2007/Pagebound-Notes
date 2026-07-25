import CoreGraphics
import Foundation

struct PageOverlayHitContext: Equatable, Sendable {
    let objects: [PageObject]
    let selectedObjectId: UUID?
    let allowsTransform: Bool
    let allowsObjectTapSelection: Bool
    let allowsBackgroundTap: Bool
    let allowsFingerObjectSelection: Bool
    let isEditingText: Bool
    let editingTextObjectId: UUID?
    let textToolPhase: TextToolPhase
    let pageSize: CGSize
    /// When true (object-shape mode), unfilled shape interiors count as hits for selection.
    let allowsShapeInteriorSelection: Bool

    @MainActor
    static func make(viewModel: PageViewModel) -> PageOverlayHitContext {
        let policy = viewModel.interactionPolicy
        let allowsShapeInterior = {
            if case .shapes = viewModel.toolSession.selectedTool,
               viewModel.toolSession.isObjectShapeMode {
                return true
            }
            return false
        }()
        return PageOverlayHitContext(
            objects: viewModel.sortedObjects,
            selectedObjectId: viewModel.selectedObjectId,
            allowsTransform: policy.allowsObjectTransform,
            allowsObjectTapSelection: policy.allowsObjectTapSelection,
            allowsBackgroundTap: policy.allowsBackgroundTap,
            allowsFingerObjectSelection: policy.allowsFingerObjectSelection,
            isEditingText: viewModel.isEditingText,
            editingTextObjectId: viewModel.editingTextObjectId,
            textToolPhase: viewModel.textToolPhase,
            pageSize: viewModel.pageDimensions,
            allowsShapeInteriorSelection: allowsShapeInterior
        )
    }
}

enum PageOverlayHitTesting {
    static func claimsHit(at point: CGPoint, context: PageOverlayHitContext) -> Bool {
        guard context.pageSize.width > 0, context.pageSize.height > 0 else { return false }
        guard CGRect(origin: .zero, size: context.pageSize).contains(point) else { return false }

        if context.isEditingText,
           let editingId = context.editingTextObjectId,
           let object = context.objects.first(where: { $0.id == editingId }),
           case .text(let textBox) = object {
            let frame = textBox.geometry.frame.cgRect.insetBy(dx: -PageObjectHitTesting.tapSlop, dy: -PageObjectHitTesting.tapSlop)
            if frame.contains(point) {
                return true
            }
            if context.allowsBackgroundTap {
                return true
            }
            return false
        }

        if context.allowsTransform,
           let selectedId = context.selectedObjectId,
           let object = context.objects.first(where: { $0.id == selectedId }) {
            if handleAt(point, object: object) != nil {
                return true
            }
            if bodyContains(point, object: object, context: context) {
                return true
            }
            if context.allowsBackgroundTap {
                return true
            }
        }

        if context.allowsObjectTapSelection {
            let hitsObject = context.objects.reversed().contains(where: { object in
                hitTestContains(point, object: object, context: context)
            })
            if hitsObject {
                // Ink/lasso/eraser: unselected bodies pass through to PKCanvasView.
                // Finger tap-select uses a finger-only gesture on the canvas.
                if context.allowsFingerObjectSelection {
                    return false
                }
                return true
            }
        }

        if context.allowsBackgroundTap {
            return true
        }

        return false
    }

    private static func handleAt(_ location: CGPoint, object: PageObject) -> ObjectTransformHandle? {
        let frame = object.frame
        let rotation = objectRotation(for: object)
        let hitRadius = ObjectTransformSession.handleHitSize / 2

        for handle in handles(for: object) {
            let point = handle.point(in: frame, rotation: rotation)
            let distance = hypot(location.x - point.x, location.y - point.y)
            if distance <= hitRadius {
                return handle
            }
        }
        return nil
    }

    private static func bodyContains(
        _ location: CGPoint,
        object: PageObject,
        context: PageOverlayHitContext
    ) -> Bool {
        hitTestContains(location, object: object, context: context, forTransform: true)
    }

    private static func hitTestContains(
        _ location: CGPoint,
        object: PageObject,
        context: PageOverlayHitContext,
        forTransform: Bool = false
    ) -> Bool {
        let isSelected = context.selectedObjectId == object.id
        let allowsTransform = forTransform && context.allowsTransform && isSelected

        switch object {
        case .shape(let shapeObject):
            return PageObjectHitTesting.contains(
                location,
                in: shapeObject,
                isSelected: isSelected,
                allowsTransform: allowsTransform,
                allowUnfilledInterior: context.allowsShapeInteriorSelection
            )
        default:
            return PageObjectHitTesting.contains(location, in: object)
        }
    }

    private static func handles(for object: PageObject) -> [ObjectTransformHandle] {
        switch object {
        case .text:
            [.topLeft, .topRight, .bottomLeft, .bottomRight]
        case .image, .shape:
            ObjectTransformHandle.allCases
        }
    }

    private static func objectRotation(for object: PageObject) -> Double {
        switch object {
        case .text:
            0
        case .image(let image):
            image.geometry.rotation
        case .shape(let shape):
            shape.geometry.rotation
        }
    }
}
