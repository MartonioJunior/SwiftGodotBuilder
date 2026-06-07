import SwiftGodot
/// Result builder for composing `[InputEvent]` in a DSL block.
///
/// Enables:
/// ```swift
/// Action("jump") {
///   Key(.space)
///   JoyButton(0, .a)
/// }
/// ```
@_documentation(visibility: private)
@resultBuilder
public enum InputEventBuilder {
    public static func buildBlock(_ parts: [InputEvent]...) -> [InputEvent] { parts.flatMap { $0 } }
    public static func buildExpression(_ event: InputEvent) -> [InputEvent] { [event] }
    public static func buildExpression(_ events: [InputEvent]) -> [InputEvent] { events }
    public static func buildOptional(_ event: [InputEvent]?) -> [InputEvent] { event ?? [] }
    public static func buildEither(first: [InputEvent]) -> [InputEvent] { first }
    public static func buildEither(second: [InputEvent]) -> [InputEvent] { second }
    public static func buildArray(_ arr: [[InputEvent]]) -> [InputEvent] { arr.flatMap { $0 } }
}
