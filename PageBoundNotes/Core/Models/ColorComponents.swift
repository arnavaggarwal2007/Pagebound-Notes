import CoreGraphics
import Foundation

struct ColorComponents: Codable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    static let white = ColorComponents(red: 1, green: 1, blue: 1, alpha: 1)
}
