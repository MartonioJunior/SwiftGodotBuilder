//
//  Keyboard.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

/// Abstraction that represents a Keyboard.
public enum Keyboard {
    /// Defines an input event for a given keyboard key.
    /// - Parameter key: Key to be evaluated.
    /// - Returns: `InputEventKey` for `key`.
    static func key(_ key: Key) -> InputEventKey {
        .init(key)
    }
}
