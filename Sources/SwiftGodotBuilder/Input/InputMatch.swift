import SwiftGodot

public enum InputMatch {
    case any
    case pressed
    case released
    case echo
    case key(Key)
    case mouse(MouseButton)
    case joyButton(JoyButton)
    /// InputMap action
    case action(String)
}
