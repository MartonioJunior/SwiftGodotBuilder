//
//  InputEvent+Utilities.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

public extension InputEvent {
    /// Artificially triggers the input event from code.
    func invoke() { Input.parseInputEvent(self) }
}

public extension InputEventJoypadButton {
    convenience init(_ button: JoyButton, device: InputDevice) {
        self.init()
        self.device = Int32(device.id)
        self.buttonIndex = button
    }

    func matches(_ button: JoyButton, mask: BitSet<InputPhase> = .all) -> Bool {
        guard buttonIndex == button else { return false }

        return if pressed {
            mask.contains(.only(.pressed))
        } else {
            mask.contains(.only(.released))
        }
    }
}

public extension InputEventJoypadMotion {
    convenience init(axis: JoyAxis, device: InputDevice, value: Double) {
        self.init()
        self.device = Int32(device.id)
        self.axis = axis
        self.axisValue = value
    }

    func matches(_ axis: JoyAxis, mask: BitSet<InputPhase> = .all, predicate: (Double) -> Bool) -> Bool {
        guard self.axis == axis else { return false }

        return if isPressed() {
            mask.contains(.only(.pressed)) && predicate(axisValue)
        } else {
            mask.contains(.only(.released)) && predicate(axisValue)
        }
    }
}

public extension InputEventKey {
    convenience init(_ key: Key) {
        self.init()
        self.physicalKeycode = key
    }

    func matches(_ key: Key, mask: BitSet<InputPhase> = .all, acceptEcho: Bool = false) -> Bool {
        guard physicalKeycode == key else { return false }

        if echo { return acceptEcho }

        return if pressed {
            mask.contains(.only(.pressed))
        } else {
            mask.contains(.only(.released))
        }
    }
}

public extension InputEventMouseButton {
    convenience init(_ button: MouseButton) {
        self.init()
        self.buttonIndex = button
    }

    func matches(_ button: MouseButton, mask: BitSet<InputPhase> = .all) -> Bool {
        guard buttonIndex == button else { return false }

        return if pressed {
            mask.contains(.only(.pressed))
        } else {
            mask.contains(.only(.released))
        }
    }
}
