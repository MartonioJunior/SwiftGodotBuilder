//
//  Keyboard.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

/// Abstraction that represents a Keyboard.
public struct Keyboard {
    /// Defines an input event for a given keyboard key.
    /// - Parameter key: Key to be evaluated.
    /// - Returns: `InputEventKey` for `key`.
    static func key(_ key: Key) -> InputEventKey {
        .init(key)
    }
}

// MARK: Self.Input
public extension Keyboard {
    enum Input {
        /// Keyboard event using a Godot `Key` (physical scancode).
        case key(Key)
    }
}

// MARK: Self: InputSource
extension Keyboard: InputSource {
    /// Device associated with the input.
    /// 
    /// IDs 16-31 are reserved for keyboards.
    public var device: InputDevice { 16 }

    public static func unwrapEvent(_ event: InputEvent) -> Input? {
        switch event {
            case let keyEvent as InputEventKey:
                .key(keyEvent.keycode)
            default:
                nil
        }
    }

    public func wrapInput(_ input: Input) -> InputEvent {
        switch input {
            case let .key(key):
                InputEventKey(key)
        }
    }
}
