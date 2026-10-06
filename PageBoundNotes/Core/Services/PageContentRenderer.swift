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
        case .fineGraph, .coarseGraph:
            drawGraphPaper(in: context, pageSize: pageSize, gridSize: template.gridSize)
        case .cornell:
            drawCornell(in: context, pageSize: pageSize, spacing: template.lineSpacing)
        case .musicStaff:
            drawMusicStaff(in: context, pageSize: pageSize, lineSpacing: template.lineSpacing)
        case .checklist:
            drawChecklist(in: context, pageSize: pageSize, spacing: template.lineSpacing)
        case .planner:
            drawPlanner(in: context, pageSize: pageSize, rowHeight: max(template.lineSpacing, 28))
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

    private static func drawGraphPaper(in context: CGContext, pageSize: CGSize, gridSize: CGSize) {
        guard gridSize.width > 0, gridSize.height > 0 else { return }
        context.setStrokeColor(UIColor.systemGray4.withAlphaComponent(0.7).cgColor)
        context.setLineWidth(0.5)

        var x = gridSize.width
        while x < pageSize.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: pageSize.height))
            x += gridSize.width
        }
        var y = gridSize.height
        while y < pageSize.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: pageSize.width, y: y))
            y += gridSize.height
        }
        context.strokePath()
    }

    private static func drawCornell(in context: CGContext, pageSize: CGSize, spacing: CGFloat) {
        let cueWidth = pageSize.width * 0.28
        let summaryTop = pageSize.height * 0.78
        context.setStrokeColor(UIColor.systemGray3.cgColor)
        context.setLineWidth(0.75)
        context.move(to: CGPoint(x: cueWidth, y: 0))
        context.addLine(to: CGPoint(x: cueWidth, y: summaryTop))
        context.move(to: CGPoint(x: 0, y: summaryTop))
        context.addLine(to: CGPoint(x: pageSize.width, y: summaryTop))
        context.strokePath()

        guard spacing > 0 else { return }
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)
        var y = spacing
        while y < summaryTop {
            context.move(to: CGPoint(x: cueWidth, y: y))
            context.addLine(to: CGPoint(x: pageSize.width, y: y))
            y += spacing
        }
        context.strokePath()
    }

    private static func drawMusicStaff(in context: CGContext, pageSize: CGSize, lineSpacing: CGFloat) {
        let spacing = max(lineSpacing, 8)
        let staffHeight = spacing * 4
        let staffGap = spacing * 3
        context.setStrokeColor(UIColor.systemGray3.cgColor)
        context.setLineWidth(0.6)

        var originY = spacing * 2
        while originY + staffHeight < pageSize.height - spacing {
            for line in 0..<5 {
                let y = originY + CGFloat(line) * spacing
                context.move(to: CGPoint(x: spacing * 2, y: y))
                context.addLine(to: CGPoint(x: pageSize.width - spacing * 2, y: y))
            }
            originY += staffHeight + staffGap
        }
        context.strokePath()
    }

    private static func drawChecklist(in context: CGContext, pageSize: CGSize, spacing: CGFloat) {
        let row = max(spacing, 28)
        let boxSize: CGFloat = 14
        let leftInset: CGFloat = 24
        context.setStrokeColor(UIColor.systemGray3.cgColor)
        context.setLineWidth(0.75)

        var y = row
        while y < pageSize.height - row {
            let boxRect = CGRect(x: leftInset, y: y - boxSize / 2, width: boxSize, height: boxSize)
            context.addPath(UIBezierPath(roundedRect: boxRect, cornerRadius: 2).cgPath)
            context.strokePath()

            context.setStrokeColor(UIColor.systemGray4.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: leftInset + boxSize + 12, y: y))
            context.addLine(to: CGPoint(x: pageSize.width - leftInset, y: y))
            context.strokePath()

            context.setStrokeColor(UIColor.systemGray3.cgColor)
            context.setLineWidth(0.75)
            y += row
        }
    }

    private static func drawPlanner(in context: CGContext, pageSize: CGSize, rowHeight: CGFloat) {
        let columns = 2
        let columnWidth = pageSize.width / CGFloat(columns)
        context.setStrokeColor(UIColor.systemGray3.cgColor)
        context.setLineWidth(0.6)
        for column in 1..<columns {
            let x = columnWidth * CGFloat(column)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: pageSize.height))
        }
        context.strokePath()

        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.setLineWidth(0.5)
        var y = rowHeight
        while y < pageSize.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: pageSize.width, y: y))
            y += rowHeight
        }
        context.strokePath()
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

            ObjectRenderer.drawImages(
                objects: objects,
                imageLoader: imageLoader,
                in: context.cgContext,
                pageSize: dimensions
            )

            let strokeImage = strokeImage(from: drawing, bounds: bounds, scale: scale)
            strokeImage.draw(in: bounds)

            ObjectRenderer.drawForegroundObjects(
                objects: objects,
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
