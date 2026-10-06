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

    var displayName: String {
        switch self {
        case .blank: return String(localized: "Blank")
        case .collegeRuled: return String(localized: "College Ruled")
        case .wideRuled: return String(localized: "Wide Ruled (larger spacing)")
        case .dottedGrid: return String(localized: "Dotted Grid")
        case .fineGraph: return String(localized: "Fine Graph Paper")
        case .coarseGraph: return String(localized: "Coarse Graph Paper")
        case .cornell: return String(localized: "Cornell Notes")
        case .musicStaff: return String(localized: "Music Staff")
        case .checklist: return String(localized: "Checklist")
        case .planner: return String(localized: "Planner")
        }
    }
}
