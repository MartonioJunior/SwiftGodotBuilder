//
//  DOM+Godot.swift
//  SwiftGodotBuilder
//
//  Extensions to DOM types for Godot integration
//

import Foundation

// MARK: - Color Conversion

public extension DOM.Color {
    /// Converts DOM.Color to RGBA components (r, g, b, a in 0-1 range)
    func toRGBA() -> (r: Float, g: Float, b: Float, a: Float) {
        switch self {
        case .none:
            return (0, 0, 0, 0)

        case .currentColor:
            // Default to black for currentColor (would need context to resolve properly)
            return (0, 0, 0, 1)

        case .keyword(let keyword):
            let rgb = keyword.rgbi
            return (
                Float(rgb.0) / 255.0,
                Float(rgb.1) / 255.0,
                Float(rgb.2) / 255.0,
                1.0
            )

        case .rgbi(let r, let g, let b, let a):
            return (
                Float(r) / 255.0,
                Float(g) / 255.0,
                Float(b) / 255.0,
                a
            )

        case .rgbf(let r, let g, let b, let a):
            return (r, g, b, a)

        case .p3(let r, let g, let b):
            // P3 to sRGB conversion (simplified - just use as-is for now)
            return (r, g, b, 1.0)

        case .hex(let r, let g, let b):
            return (
                Float(r) / 255.0,
                Float(g) / 255.0,
                Float(b) / 255.0,
                1.0
            )
        }
    }

    /// Convenience properties for RGBA access
    var r: Float { toRGBA().r }
    var g: Float { toRGBA().g }
    var b: Float { toRGBA().b }
    var a: Float { toRGBA().a }
}
