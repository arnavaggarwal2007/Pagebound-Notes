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

    static let fineGraph = Template(
        id: "template.fine-graph",
        type: .fineGraph,
        lineSpacing: 0,
        gridSize: CGSize(width: 12, height: 12)
    )

    static let coarseGraph = Template(
        id: "template.coarse-graph",
        type: .coarseGraph,
        lineSpacing: 0,
        gridSize: CGSize(width: 28, height: 28)
    )

    static let cornell = Template(
        id: "template.cornell",
        type: .cornell,
        lineSpacing: 24,
        gridSize: .zero
    )

    static let musicStaff = Template(
        id: "template.music-staff",
        type: .musicStaff,
        lineSpacing: 10,
        gridSize: .zero
    )

    static let checklist = Template(
        id: "template.checklist",
        type: .checklist,
        lineSpacing: 36,
        gridSize: .zero
    )

    static let planner = Template(
        id: "template.planner",
        type: .planner,
        lineSpacing: 28,
        gridSize: CGSize(width: 0, height: 28)
    )

    static let all: [Template] = [
        blank,
        collegeRuled,
        wideRuled,
        dottedGrid,
        fineGraph,
        coarseGraph,
        cornell,
        musicStaff,
        checklist,
        planner
    ]

    static func template(for id: String) -> Template? {
        all.first { $0.id == id }
    }
}
