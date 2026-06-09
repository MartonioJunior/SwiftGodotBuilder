//
//  InputPhase.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 08/06/2026.
//

/// Enumerator that describes all possible phases for an input.
public enum InputPhase: Int {
    /// Input was pressed.
    case pressed = 0
    /// Input was released.
    case released = 1
    /// Input is relayed again if it's still pressed.
    /// 
    /// Used for Keyboard keys, but can be enabled for other types of input.
    case echo = 2
}

// MARK: Self: Sendable
extension InputPhase: Sendable {}
