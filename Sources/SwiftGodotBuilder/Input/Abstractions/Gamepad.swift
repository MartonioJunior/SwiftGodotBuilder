//
//  Gamepad.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

public struct Gamepad {
    // MARK: Variables
    /// Device representing the gamepad.
    var device: InputDevice
    // MARK: Initializers
    /// Creates a new gamepad.
    /// - Parameter device: Device representing the gamepad.
    public init(_ device: InputDevice) {
        self.device = device
    }
    /// Input event for a button of the gamepad.
    /// - Parameter button: Gamepad button.
    /// - Returns: Input event.
    public func button(_ button: JoyButton) -> InputEventJoypadButton {
        .init(button, device: device)
    }
    /// Input event for an axis of the gamepad.
    /// - Parameters:
    ///   - axis: Gamepad axis to check.
    ///   - value: Value of the analog stick.
    ///
    /// - Returns: Input event.
    public func axis(_ axis: JoyAxis, value: Double) -> InputEventJoypadMotion {
        .init(axis: axis, device: device, value: value)
    }
}
