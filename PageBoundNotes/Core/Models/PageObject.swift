import CoreGraphics
import Foundation

struct CodablePoint: Codable, Equatable, Sendable {
    var x: Double
    var y: Double

    init(_ point: CGPoint) {
        x = Double(point.x)
        y = Double(point.y)
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct CodableSize: Codable, Equatable, Sendable {
    var width: Double
    var height: Double

    init(_ size: CGSize) {
        width = Double(size.width)
        height = Double(size.height)
    }

    var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
}

struct CodableRect: Codable, Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ rect: CGRect) {
        x = Double(rect.origin.x)
        y = Double(rect.origin.y)
        width = Double(rect.size.width)
        height = Double(rect.size.height)
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct ObjectGeometry: Codable, Equatable, Sendable {
    var frame: CodableRect
    var rotation: Double
    var zIndex: Int

    init(frame: CGRect, rotation: Double = 0, zIndex: Int = 0) {
        self.frame = CodableRect(frame)
        self.rotation = rotation
        self.zIndex = zIndex
    }
}

struct TextBoxObject: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var geometry: ObjectGeometry
    var text: String
    var fontName: String
    var fontSize: Double
    var color: ColorComponents
    var isBold: Bool
    var isItalic: Bool

    static func makeDefault(at center: CGPoint, zIndex: Int) -> TextBoxObject {
        let size = CGSize(width: 220, height: 80)
        let frame = CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return TextBoxObject(
            id: UUID(),
            geometry: ObjectGeometry(frame: frame, zIndex: zIndex),
            text: String(localized: "Text"),
            fontName: TextBoxDefaults.fontName,
            fontSize: TextBoxDefaults.fontSize,
            color: ColorComponents(red: 0, green: 0, blue: 0, alpha: 1),
            isBold: false,
            isItalic: false
        )
    }
}

enum TextBoxDefaults {
    static let fontName = ".AppleSystemUIFont"
    static let fontSize: Double = 18
    static let availableFontNames = [
        ".AppleSystemUIFont",
        "HelveticaNeue",
        "TimesNewRomanPSMT",
        "Courier",
        "Georgia",
        "AvenirNext-Regular"
    ]
}

struct ImageObject: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var geometry: ObjectGeometry
    var imageBlobId: String
    var intrinsicSize: CodableSize

    static func makeDefault(
        imageBlobId: String,
        intrinsicSize: CGSize,
        center: CGPoint,
        zIndex: Int
    ) -> ImageObject {
        let maxDimension: CGFloat = 280
        let scale = min(maxDimension / max(intrinsicSize.width, intrinsicSize.height, 1), 1)
        let displaySize = CGSize(
            width: intrinsicSize.width * scale,
            height: intrinsicSize.height * scale
        )
        let frame = CGRect(
            x: center.x - displaySize.width / 2,
            y: center.y - displaySize.height / 2,
            width: displaySize.width,
            height: displaySize.height
        )
        return ImageObject(
            id: UUID(),
            geometry: ObjectGeometry(frame: frame, zIndex: zIndex),
            imageBlobId: imageBlobId,
            intrinsicSize: CodableSize(intrinsicSize)
        )
    }
}

struct ShapeObjectStyle: Codable, Equatable, Sendable {
    var strokeColor: ColorComponents
    var strokeWidth: Double
    var fillColor: ColorComponents?

    static let `default` = ShapeObjectStyle(
        strokeColor: ColorComponents(red: 0, green: 0, blue: 0, alpha: 1),
        strokeWidth: 3,
        fillColor: nil
    )
}

struct ShapeObject: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var geometry: ObjectGeometry
    var kind: ShapeKind
    var style: ShapeObjectStyle
    var startPoint: CodablePoint?
    var endPoint: CodablePoint?

    static func make(
        kind: ShapeKind,
        from start: CGPoint,
        to end: CGPoint,
        style: ShapeObjectStyle,
        zIndex: Int
    ) -> ShapeObject {
        let snappedEnd = ShapeStrokeBuilder.snappedEnd(from: start, to: end, kind: kind)
        switch kind {
        case .rectangle, .ellipse:
            let rect = ShapeStrokeBuilder.normalizedRect(from: start, to: snappedEnd)
            return ShapeObject(
                id: UUID(),
                geometry: ObjectGeometry(frame: rect, zIndex: zIndex),
                kind: kind,
                style: style,
                startPoint: nil,
                endPoint: nil
            )
        case .line, .arrow:
            let rect = ShapeStrokeBuilder.normalizedRect(from: start, to: snappedEnd)
            return ShapeObject(
                id: UUID(),
                geometry: ObjectGeometry(frame: rect.insetBy(dx: -8, dy: -8), zIndex: zIndex),
                kind: kind,
                style: style,
                startPoint: CodablePoint(start),
                endPoint: CodablePoint(snappedEnd)
            )
        }
    }

    func lineEndpoints() -> (CGPoint, CGPoint)? {
        guard let startPoint, let endPoint else { return nil }
        return (startPoint.cgPoint, endPoint.cgPoint)
    }
}

enum PageObject: Identifiable, Equatable, Sendable {
    case text(TextBoxObject)
    case image(ImageObject)
    case shape(ShapeObject)

    var id: UUID {
        switch self {
        case .text(let object): object.id
        case .image(let object): object.id
        case .shape(let object): object.id
        }
    }

    var zIndex: Int {
        switch self {
        case .text(let object): object.geometry.zIndex
        case .image(let object): object.geometry.zIndex
        case .shape(let object): object.geometry.zIndex
        }
    }

    var frame: CGRect {
        switch self {
        case .text(let object): object.geometry.frame.cgRect
        case .image(let object): object.geometry.frame.cgRect
        case .shape(let object): object.geometry.frame.cgRect
        }
    }
}

extension PageObject: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case image
        case shape
    }

    private enum ObjectType: String, Codable {
        case text
        case image
        case shape
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ObjectType.self, forKey: .type)
        switch type {
        case .text:
            self = .text(try container.decode(TextBoxObject.self, forKey: .text))
        case .image:
            self = .image(try container.decode(ImageObject.self, forKey: .image))
        case .shape:
            self = .shape(try container.decode(ShapeObject.self, forKey: .shape))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let object):
            try container.encode(ObjectType.text, forKey: .type)
            try container.encode(object, forKey: .text)
        case .image(let object):
            try container.encode(ObjectType.image, forKey: .type)
            try container.encode(object, forKey: .image)
        case .shape(let object):
            try container.encode(ObjectType.shape, forKey: .type)
            try container.encode(object, forKey: .shape)
        }
    }
}

struct PageObjectsDocument: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version: Int
    var objects: [PageObject]

    static var empty: PageObjectsDocument {
        PageObjectsDocument(version: currentVersion, objects: [])
    }

    var sortedObjects: [PageObject] {
        objects.sorted { $0.zIndex < $1.zIndex }
    }

    func imageBlobIds() -> [String] {
        objects.compactMap { object in
            if case .image(let imageObject) = object {
                return imageObject.imageBlobId
            }
            return nil
        }
    }

    mutating func assignNextZIndex() -> Int {
        (objects.map(\.zIndex).max() ?? -1) + 1
    }
}
