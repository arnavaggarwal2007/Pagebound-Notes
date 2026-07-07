import CoreGraphics
import Foundation

struct Template: Identifiable, Codable, Equatable, Sendable {
    let id: String
    var type: TemplateType
    var lineSpacing: CGFloat
    var gridSize: CGSize
    var backgroundColor: ColorComponents

    init(
        id: String,
        type: TemplateType,
        lineSpacing: CGFloat,
        gridSize: CGSize,
        backgroundColor: ColorComponents = .white
    ) {
        self.id = id
        self.type = type
        self.lineSpacing = lineSpacing
        self.gridSize = gridSize
        self.backgroundColor = backgroundColor
    }
}
