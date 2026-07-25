import SwiftUI

struct ObjectTransformPreviewState: Equatable {
    var dragTranslation: CGSize = .zero
    var resizeTranslation: CGSize = .zero
    var rotationDelta: Double = 0
    var activeHandle: ObjectTransformHandle?
    var gestureStartFrame: CGRect = .zero
    var gestureStartRotation: Double = 0
    var isTransformDragging = false

    static let idle = ObjectTransformPreviewState()
}

enum ObjectDisplayGeometry {
    static func displayFrame(
        for object: PageObject,
        selectedObjectId: UUID?,
        preview: ObjectTransformPreviewState
    ) -> CGRect {
        guard selectedObjectId == object.id else { return object.frame }
        var frame = object.frame
        if preview.activeHandle == nil, preview.dragTranslation != .zero {
            frame = ObjectTransformSession.movedFrame(frame, by: preview.dragTranslation)
        } else if let handle = preview.activeHandle, handle.isCorner {
            frame = resizedPreviewFrame(for: object, preview: preview, handle: handle)
        }
        return frame
    }

    static func displayRotation(
        for object: PageObject,
        selectedObjectId: UUID?,
        preview: ObjectTransformPreviewState
    ) -> Double {
        objectRotation(for: object) + (selectedObjectId == object.id ? preview.rotationDelta : 0)
    }

    private static func resizedPreviewFrame(
        for object: PageObject,
        preview: ObjectTransformPreviewState,
        handle: ObjectTransformHandle
    ) -> CGRect {
        let lockedAspect: CGFloat?
        if case .image(let imageObject) = object {
            lockedAspect = ObjectTransformSession.imageAspectRatio(for: imageObject)
        } else {
            lockedAspect = nil
        }

        return ObjectTransformSession.resizedFrame(
            from: preview.gestureStartFrame,
            handle: handle,
            delta: preview.resizeTranslation,
            rotation: preview.gestureStartRotation,
            lockedAspect: lockedAspect
        )
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
