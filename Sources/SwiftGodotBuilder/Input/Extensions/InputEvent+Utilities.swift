//
//  InputEvent+Utilities.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

public extension InputEvent {
    convenience init(device: InputDevice) {
        self.init()
        self.device = Int32(device.id)
    }
    /// Artificially triggers the input event from code.
    func invoke() { Input.parseInputEvent(self) }
}

public extension InputEventJoypadButton {
    convenience init(_ button: JoyButton, device: InputDevice) {
        self.init(device: device)
        self.buttonIndex = button
    }
}

public extension InputEventJoypadMotion {
    convenience init(axis: JoyAxis, device: InputDevice, value: Double) {
        self.init(device: device)
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
