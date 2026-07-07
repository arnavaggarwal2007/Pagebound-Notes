import CoreGraphics
import Foundation

extension PageSize {
    /// Standard PDF point dimensions (72 pt per inch).
    func dimensions(in orientation: PageOrientation) -> CGSize {
        let portrait: CGSize
        switch self {
        case .letter:
            portrait = CGSize(width: 612, height: 792)
        case .a4:
            portrait = CGSize(width: 595, height: 842)
        case .custom:
            portrait = CGSize(width: 612, height: 792)
        }

        switch orientation {
        case .portrait:
            return portrait
        case .landscape:
            return CGSize(width: portrait.height, height: portrait.width)
        }
    }
}

enum PageLayoutConstants {
    static let safeMarginInset: CGFloat = 36
}
