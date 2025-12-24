import Foundation
import SwiftGodot

// MARK: - ColorPicker Elements

/// An element that can appear in a ColorPicker's preset list.
public protocol ColorPresetElement: Sendable {
    /// Adds this element to the given ColorPicker.
    func addTo(_ picker: ColorPicker)
}

/// A color preset swatch.
public struct Preset: ColorPresetElement, Sendable {
    public let color: Color

    public init(_ color: Color) {
        self.color = color
    }

    /// Creates a preset from RGB values (0-255).
    public init(r: Int, g: Int, b: Int, a: Int = 255) {
        color = Color(
            r: Float(r) / 255.0,
            g: Float(g) / 255.0,
            b: Float(b) / 255.0,
            a: Float(a) / 255.0
        )
    }

    /// Creates a preset from a hex string (e.g., "#FF0000" or "FF0000").
    public init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = Float((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Float((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Float(rgbValue & 0x0000FF) / 255.0

        color = Color(r: r, g: g, b: b, a: 1.0)
    }

    public func addTo(_ picker: ColorPicker) {
        picker.addPreset(color: color)
    }
}

// MARK: - Common Color Presets

public extension Preset {
    /// Basic color presets.
    static let red = Preset(.red)
    static let green = Preset(.green)
    static let blue = Preset(.blue)
    static let yellow = Preset(.yellow)
    static let cyan = Preset(.cyan)
    static let magenta = Preset(.magenta)
    static let white = Preset(.white)
    static let black = Preset(.black)
    static let gray = Preset(.gray)
    static let orange = Preset(Color(r: 1, g: 0.5, b: 0, a: 1))
    static let purple = Preset(Color(r: 0.5, g: 0, b: 1, a: 1))
    static let pink = Preset(Color(r: 1, g: 0.4, b: 0.7, a: 1))
}

// MARK: - ColorPreset Result Builder

@resultBuilder
public struct ColorPresetBuilder {
    public static func buildExpression(_ element: ColorPresetElement) -> [ColorPresetElement] {
        [element]
    }

    public static func buildExpression(_ color: Color) -> [ColorPresetElement] {
        [Preset(color)]
    }

    public static func buildBlock(_ components: [ColorPresetElement]...) -> [ColorPresetElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [ColorPresetElement]?) -> [ColorPresetElement] {
        component ?? []
    }

    public static func buildEither(first component: [ColorPresetElement]) -> [ColorPresetElement] {
        component
    }

    public static func buildEither(second component: [ColorPresetElement]) -> [ColorPresetElement] {
        component
    }

    public static func buildArray(_ components: [[ColorPresetElement]]) -> [ColorPresetElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<ColorPicker> Extension

public extension GNode where T == ColorPicker {
    /// Creates a ColorPicker with preset color swatches.
    ///
    /// ### Example
    /// ```swift
    /// ColorPicker$ {
    ///     Preset(.red)
    ///     Preset(.green)
    ///     Preset(.blue)
    ///     Preset(hex: "#FF6600")
    ///     Preset(r: 128, g: 0, b: 255)
    /// }
    /// .onColorChanged { color in
    ///     print("Color: \(color)")
    /// }
    /// ```
    ///
    /// Using static presets:
    /// ```swift
    /// ColorPicker$ {
    ///     Preset.red
    ///     Preset.orange
    ///     Preset.yellow
    ///     Preset.green
    ///     Preset.blue
    ///     Preset.purple
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @ColorPresetBuilder presets: () -> [ColorPresetElement]) {
        let elements = presets()
        self.init(name, make: {
            let picker = ColorPicker()
            for element in elements {
                element.addTo(picker)
            }
            return picker
        })
    }

    /// Connects to the `color_changed` signal.
    func onColorChanged(_ handler: @escaping (Color) -> Void) -> Self {
        configure { picker in
            picker.colorChanged.connect { color in
                handler(color)
            }
        }
    }

    /// Connects to the `preset_added` signal.
    func onPresetAdded(_ handler: @escaping (Color) -> Void) -> Self {
        configure { picker in
            picker.presetAdded.connect { color in
                handler(color)
            }
        }
    }

    /// Connects to the `preset_removed` signal.
    func onPresetRemoved(_ handler: @escaping (Color) -> Void) -> Self {
        configure { picker in
            picker.presetRemoved.connect { color in
                handler(color)
            }
        }
    }
}

// MARK: - GNode<ColorPickerButton> Extension

public extension GNode where T == ColorPickerButton {
    /// Connects to the `color_changed` signal.
    func onColorChanged(_ handler: @escaping (Color) -> Void) -> Self {
        configure { button in
            button.colorChanged.connect { color in
                handler(color)
            }
        }
    }

    /// Connects to the `picker_created` signal.
    func onPickerCreated(_ handler: @escaping () -> Void) -> Self {
        configure { button in
            button.pickerCreated.connect {
                handler()
            }
        }
    }

    /// Connects to the `popup_closed` signal.
    func onPopupClosed(_ handler: @escaping () -> Void) -> Self {
        configure { button in
            button.popupClosed.connect {
                handler()
            }
        }
    }
}
