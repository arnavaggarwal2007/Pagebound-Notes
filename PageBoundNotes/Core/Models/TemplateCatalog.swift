import CoreGraphics
import Foundation

enum TemplateCatalog {
    static let blank = Template(
        id: "template.blank",
        type: .blank,
        lineSpacing: 0,
        gridSize: .zero
    )

    static let collegeRuled = Template(
        id: "template.college-ruled",
        type: .collegeRuled,
        lineSpacing: 24,
        gridSize: .zero
    )

    static let wideRuled = Template(
        id: "template.wide-ruled",
        type: .wideRuled,
        lineSpacing: 32,
        gridSize: .zero
    )

    static let dottedGrid = Template(
        id: "template.dotted-grid",
        type: .dottedGrid,
        lineSpacing: 0,
        gridSize: CGSize(width: 24, height: 24)
    )

    static let all: [Template] = [blank, collegeRuled, wideRuled, dottedGrid]

    static func template(for id: String) -> Template? {
        all.first { $0.id == id }
    }
}
