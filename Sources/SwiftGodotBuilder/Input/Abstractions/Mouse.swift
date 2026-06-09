//
//  Mouse.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

/// Abstraction that represents this mouse button.
public enum Mouse {
    /// Creates an input event for a mouse button.
    /// - Parameter button: Mouse button to be used.
    /// - Returns: `InputEventMouseButton` for `button`.
    static func button(_ button: MouseButton) -> InputEventMouseButton {
        .init(button)
    }
}
