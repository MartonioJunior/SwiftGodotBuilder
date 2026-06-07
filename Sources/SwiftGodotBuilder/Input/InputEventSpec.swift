import SwiftGodot
/// Describes a single input event in a declarative, strongly-typed way.
/// Use these to build actions without hard-coding raw integers.
public enum InputEventEnumerator {
    // MARK: Cases
    /// Keyboard event using a Godot `Key` (physical scancode).
    case key(_ key: Key)
    /// Joypad button event for a specific device and button.
    case joyButton(button: JoyButton, device: InputDevice)
    /// Joypad axis motion event with a signed axis value (−1.0...1.0).
    case joyAxis(axis: JoyAxis, device: InputDevice, value: Double)
    /// Mouse button event.
    case mouseButton(button: MouseButton)
    // MARK: Methods
    /// Builds the corresponding Godot `InputEvent` instance.
    ///
    /// This materializes the declarative spec into an engine object that
    /// can be registered with `InputMap`. Defaults `pressed` to `false`
    /// for button/keyboard types to represent the "binding" rather than state.
    func make() -> InputEvent {
        switch self {
            case let .key(key):
                InputEventKey(key)
            case let .joyButton(button, device):
                InputEventJoypadButton(button, device: device)
            case let .joyAxis(axis, device, value):
                InputEventJoypadMotion(axis: axis, device: device, value: value)
            case let .mouseButton(button):
                InputEventMouseButton(button)
        }
    }
}
