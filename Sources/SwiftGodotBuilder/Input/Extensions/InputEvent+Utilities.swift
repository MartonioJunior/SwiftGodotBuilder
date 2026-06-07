//
//  InputEvent+Utilities.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

public extension InputEvent {
    static func joypadButton(_ button: JoyButton, device: InputDevice) -> InputEventJoypadButton {
        let event = InputEventJoypadButton()
        event.device = Int32(device.id)
        event.buttonIndex = button
        return event
    }

    static func joypadAxis(_ axis: JoyAxis, device: InputDevice, value: Double) -> InputEventJoypadMotion {
        let event = InputEventJoypadMotion()
        event.device = Int32(device.id)
        event.axis = axis
        event.axisValue = value
        return event
    }

    static func key(_ key: Key) -> InputEventKey {
        let event = InputEventKey()
        event.physicalKeycode = key
        return event
    }

    static func mouseButton(_ button: MouseButton) -> InputEventMouseButton {
        let event = InputEventMouseButton()
        event.buttonIndex = button
        return event
    }
}

// MARK: - Sugar for event literals inside InputEventBuilder
/// Shorthand constructor for a keyboard event.
@inlinable public func Key(_ key: Key) -> InputEvent { .key(key) }
/// Shorthand constructor for a joypad button event.
@inlinable public func JoyButton(_ button: JoyButton, device: InputDevice) -> InputEvent {
    .joypadButton(button, device: device)
}
/// Shorthand constructor for a joypad axis event.
@inlinable public func JoyAxis(_ axis: JoyAxis, device: InputDevice, _ value: Double) -> InputEvent {
    .joypadAxis(axis, device: device, value: value)
}
/// Shorthand constructor for a mouse button event (by integer index).
@inlinable public func MouseButton(_ button: MouseButton) -> InputEvent { .mouseButton(button) }

// MARK: Array (EX)
public extension Array where Element == InputEvent {
    static func combined(
        device: InputDevice,
        axis: (id: JoyAxis, value: Double)? = nil,
        key: Key? = nil,
        button: JoyButton? = nil,
    ) -> Self {
        [
            axis.map { .joypadAxis($0.id, device: device, value: $0.value) },
            key.map { .key($0) },
            button.map { .joypadButton($0, device: device) }
        ].compactMap(\.self)
    }
}
