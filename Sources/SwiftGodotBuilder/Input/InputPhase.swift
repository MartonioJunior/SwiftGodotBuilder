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

// MARK: BitSet (EX)
import SwiftGodot

public extension BitSet where Base == InputPhase {
    func validate(_ event: InputEvent) -> Bool {
        if event.isPressed() {
            contains(.only(.pressed))
        } else if event.isReleased() {
            contains(.only(.released))
        } else {
            contains(.only(.echo))
        }
    }
}
