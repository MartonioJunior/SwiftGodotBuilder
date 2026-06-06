import SwiftGodot
/// Describes a single input event in a declarative, strongly-typed way.
/// Use these to build actions without hard-coding raw integers.
public enum InputEventSpec {
    // MARK: Cases
    /// Keyboard event using a Godot `Key` (physical scancode).
    case key(_ key: Key)
    /// Joypad button event for a specific device and button.
    case joyButton(button: JoyButton, device: Int)
    /// Joypad axis motion event with a signed axis value (−1.0...1.0).
    case joyAxis(axis: JoyAxis, device: Int, value: Double)
    /// Mouse button event by numerical index (mapped to `MouseButton`).
    case mouseButton(index: Int)
    // MARK: Methods
    /// Builds the corresponding Godot `InputEvent` instance.
    ///
    /// This materializes the declarative spec into an engine object that
    /// can be registered with `InputMap`. Defaults `pressed` to `false`
    /// for button/keyboard types to represent the "binding" rather than state.
    func make() -> InputEvent {
        switch self {
            case let .key(key):
                let e = InputEventKey()
                e.physicalKeycode = key
                return e
            case let .joyButton(button, device):
                let e = InputEventJoypadButton()
                e.device = Int32(device)
                e.buttonIndex = button
                return e
            case let .joyAxis(axis, device, value):
                let e = InputEventJoypadMotion()
                e.device = Int32(device)
                e.axis = axis
                e.axisValue = value
                return e
            case let .mouseButton(index):
                let e = InputEventMouseButton()
                e.buttonIndex = MouseButton(rawValue: Int64(index)) ?? .none
                return e
        }
    }
}

// MARK: - Sugar for event literals inside InputEventBuilder
/// Shorthand constructor for a keyboard event.
@inlinable public func Key(_ key: Key) -> InputEventSpec { .key(key) }
/// Shorthand constructor for a joypad button event.
@inlinable public func JoyButton(_ button: JoyButton, device: Int) -> InputEventSpec {
    .joyButton(button: button, device: device)
}
/// Shorthand constructor for a joypad axis event.
@inlinable public func JoyAxis(_ axis: JoyAxis, device: Int, _ value: Double) -> InputEventSpec {
    .joyAxis(axis: axis, device: device, value: value)
}
/// Shorthand constructor for a mouse button event (by integer index).
@inlinable public func MouseButton(_ index: Int) -> InputEventSpec { .mouseButton(index: index) }
