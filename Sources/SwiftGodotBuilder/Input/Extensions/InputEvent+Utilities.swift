//
//  InputEvent+Utilities.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

public extension InputEventJoypadButton {
    convenience init(_ button: JoyButton, device: InputDevice) {
        self.init()
        self.device = Int32(device.id)
        self.buttonIndex = button
    }
}

public extension InputEventJoypadMotion {
    convenience init(axis: JoyAxis, device: InputDevice, value: Double) {
        self.init()
        self.device = Int32(device.id)
        self.axis = axis
        self.axisValue = value
    }
}

public extension InputEventKey {
    convenience init(_ key: Key) {
        self.init()
        self.physicalKeycode = key
    }
}

public extension InputEventMouseButton {
    convenience init(_ button: MouseButton) {
        self.init()
        self.buttonIndex = button
    }
}

// MARK: - Sugar for event literals inside InputEventBuilder
/// Shorthand constructor for a keyboard event.
// @inlinable public func Key(_ key: Key) -> InputEvent { .key(key) }
/// Shorthand constructor for a joypad button event.
/// Shorthand constructor for a joypad axis event.
/// Shorthand constructor for a mouse button event (by integer index).
// @inlinable public func MouseButton(_ button: MouseButton) -> InputEvent { .mouseButton(button) }

// MARK: Array (EX)
public extension Array where Element == InputEvent {
    static func combined(
        device: InputDevice,
        axis: (id: JoyAxis, value: Double)? = nil,
        key: Key? = nil,
        button: JoyButton? = nil,
    ) -> Self {
        [
            axis.map { InputEventJoypadMotion($0.id, device: device, value: $0.value) },
            key.map { InputEventKey($0) },
            button.map { InputEventJoypadButton($0, device: device) }
        ].compactMap(\.self)
    }
}
