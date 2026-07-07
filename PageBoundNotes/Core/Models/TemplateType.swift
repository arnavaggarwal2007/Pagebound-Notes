import Foundation

enum TemplateType: String, Codable, CaseIterable, Sendable {
    case blank
    case collegeRuled
    case wideRuled
    case dottedGrid
    case fineGraph
    case coarseGraph
    case cornell
    case musicStaff
    case checklist
    case planner
}
