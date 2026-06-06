import SwiftGodot

public enum InputMatch {
    case any
    case pressed, released, echo
    case key(Key)
    case mouse(MouseButton)
    case joyButton(JoyButton)
    /// InputMap action
    case action(String)
}
