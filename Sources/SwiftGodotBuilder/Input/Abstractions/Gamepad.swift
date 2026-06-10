//
//  Gamepad.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

/// Abstraction that represents a Gamepad.
public struct Gamepad {
    // MARK: Variables
    /// Device representing the gamepad.
    public let device: InputDevice
    // MARK: Initializers
    /// Creates a new gamepad.
    /// - Parameter device: Device representing the gamepad.
    public init(_ device: InputDevice) {
        self.device = device
    }
    // MARK: Methods
    /// Input event for an axis of the gamepad.
    /// - Parameters:
    ///   - axis: Gamepad axis to check.
    ///   - value: Value of the analog stick.
    ///
    /// - Returns: Input event.
    public func axis(_ axis: Axis, value: Double) -> InputEventJoypadMotion {
        .init(axis: axis, device: device, value: value)
    }
    /// Input event for a button of the gamepad.
    /// - Parameter button: Gamepad button.
    /// - Returns: Input event.
    public func button(_ button: Button) -> InputEventJoypadButton {
        .init(button, device: device)
    }
}

// MARK: Self.Axis
public extension Gamepad {
    typealias Axis = JoyAxis
}

public extension Gamepad.Axis {
    func positioned(at value: Double) -> Gamepad.Input {
        .axis(self, value: value)
    }
}

// MARK: Self.Button
public extension Gamepad {
    typealias Button = JoyButton
}

// MARK: Self.Input
public extension Gamepad {
    /// Input event for the gamepad.
    enum Input {
        /// Input event for an axis of the gamepad with a signed value (−1.0...1.0).
        case axis(Axis, value: Double)
        /// Input event for a button of the gamepad.
        case button(Button)
    }
}

// MARK: Self: InputSource
extension Gamepad: InputSource {
    public static func unwrapEvent(_ event: InputEvent) -> Input? {
        switch event {
            case let axisEvent as InputEventJoypadMotion:
                .axis(axisEvent.axis, value: axisEvent.axisValue)
            case let buttonEvent as InputEventJoypadButton:
                .button(buttonEvent.buttonIndex)
            default:
                nil
        }
    }

    public func wrapInput(_ input: Input) -> InputEvent {
        switch input {
            case let .axis(axis, value: value):
                InputEventJoypadMotion(axis: axis, device: device, value: value)
            case let .button(button):
                InputEventJoypadButton(button, device: device)
        }
    }
}
