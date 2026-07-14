import CoreGraphics
import Foundation
import PencilKit
import UIKit

struct PageRenderSnapshot: Sendable {
    let pageId: UUID
    let templateId: String
    let orientation: PageOrientation
    let strokeData: Data?
    let objectsData: Data?

    init(page: Page, strokeData: Data?, objectsData: Data? = nil) {
        pageId = page.id
        templateId = page.templateId
        orientation = page.orientation
        self.strokeData = strokeData
        self.objectsData = objectsData
    }

    var drawing: PKDrawing {
        guard
            let strokeData,
            let decoded = try? StrokeSerialization.decode(strokeData)
        else {
            return StrokeSerialization.emptyDrawing()
        }
        return decoded
    }

    var objectsDocument: PageObjectsDocument {
        guard
            let objectsData,
            let decoded = try? ObjectSerialization.decode(objectsData)
        else {
            return .empty
        }
        return decoded
    }
}

enum TemplateRenderer {
    static func draw(template: Template, in context: CGContext, pageSize: CGSize) {
        let rect = CGRect(origin: .zero, size: pageSize)
        context.saveGState()
        context.setFillColor(UIColor.white.cgColor)
        context.fill(rect)

        switch template.type {
        case .blank:
            break
        case .collegeRuled, .wideRuled:
            drawRuledLines(in: context, pageSize: pageSize, spacing: template.lineSpacing)
        case .dottedGrid:
            drawDottedGrid(in: context, pageSize: pageSize, gridSize: template.gridSize)
        case .fineGraph, .coarseGraph, .cornell, .musicStaff, .checklist, .planner:
            break
        }

        context.restoreGState()
    }

    private static func drawRuledLines(in context: CGContext, pageSize: CGSize, spacing: CGFloat) {
        guard spacing > 0 else { return }
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)

        var y = spacing
        while y < pageSize.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: pageSize.width, y: y))
            y += spacing
        }
        context.strokePath()
    }

    private static func drawDottedGrid(in context: CGContext, pageSize: CGSize, gridSize: CGSize) {
        guard gridSize.width > 0, gridSize.height > 0 else { return }
        context.setFillColor(UIColor.systemGray4.cgColor)

        var y = gridSize.height
        while y < pageSize.height {
            var x = gridSize.width
            while x < pageSize.width {
                let dot = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                context.fillEllipse(in: dot)
                x += gridSize.width
            }
            y += gridSize.height
        }
    }
}

enum PageContentRenderer {
    static func renderPage(
        template: Template,
        drawing: PKDrawing,
        objects: [PageObject] = [],
        imageLoader: ((String) -> UIImage?) = { _ in nil },
        pageSize: PageSize,
        orientation: PageOrientation,
        scale: CGFloat = 2.0
    ) -> UIImage {
        let dimensions = pageSize.dimensions(in: orientation)
        let bounds = CGRect(origin: .zero, size: dimensions)

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: dimensions, format: format)

        return renderer.image { context in
            TemplateRenderer.draw(template: template, in: context.cgContext, pageSize: dimensions)

            let strokeImage = strokeImage(from: drawing, bounds: bounds, scale: scale)
            strokeImage.draw(in: bounds)

            ObjectRenderer.draw(
                objects: objects,
                imageLoader: imageLoader,
                in: context.cgContext,
                pageSize: dimensions
            )
        }
    }

    private static func strokeImage(from drawing: PKDrawing, bounds: CGRect, scale: CGFloat) -> UIImage {
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        var image = UIImage()
        lightTraits.performAsCurrent {
            image = drawing.image(from: bounds, scale: scale)
        }
        return image
    }

    static func renderThumbnail(
        snapshot: PageRenderSnapshot,
        book: Book,
        imageLoader: ((String) -> UIImage?) = { _ in nil }
    ) -> UIImage? {
        let template = TemplateCatalog.template(for: snapshot.templateId) ?? TemplateCatalog.blank
        let fullImage = renderPage(
            template: template,
            drawing: snapshot.drawing,
            objects: snapshot.objectsDocument.sortedObjects,
            imageLoader: imageLoader,
            pageSize: book.pageSize,
            orientation: snapshot.orientation,
            scale: 1.0
        )

        let targetSize = CGSize(width: 72, height: 96)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            fullImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
