import CoreGraphics
import Foundation

struct ZoomSettings: Codable, Equatable, Sendable {
    var returnHeights: [TemplateType: CGFloat]

    init(returnHeights: [TemplateType: CGFloat] = [:]) {
        self.returnHeights = returnHeights
    }

    func returnHeight(for template: Template) -> CGFloat {
        if let override = returnHeights[template.type], override > 0 {
            return override
        }
        return Self.defaultReturnHeight(for: template)
    }

    static func defaultReturnHeight(for template: Template) -> CGFloat {
        if template.lineSpacing > 0 {
            return template.lineSpacing
        }
        if template.gridSize.height > 0 {
            return template.gridSize.height
        }
        return 24
    }
}
