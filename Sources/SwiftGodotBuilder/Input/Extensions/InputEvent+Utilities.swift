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
