//
//  GodotInputAction.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

/// Polling mechanism for querying the state of input actions in Godot.
public protocol GodotInputAction {
    /// Type of signal returned by this action.
    associatedtype Value
    /// Was the action just pressed this frame?
    var isJustPressed: Bool { get }
    /// Was the action just released this frame?
    var isJustReleased: Bool { get }
    /// Is the action currently pressed?
    var isPressed: Bool { get }
    /// Raw signal value without deadzone processing.
    var rawStrength: Value { get }
    /// Raw signal value of the input action.
    var strength: Value { get }
}
