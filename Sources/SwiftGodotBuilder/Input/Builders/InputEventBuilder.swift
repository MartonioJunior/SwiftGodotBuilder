/// Result builder for composing `[InputEventSpec]` in a DSL block.
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
    public static func buildBlock(_ parts: [InputEventSpec]...) -> [InputEventSpec] { parts.flatMap { $0 } }
    public static func buildExpression(_ event: InputEventSpec) -> [InputEventSpec] { [event] }
    public static func buildExpression(_ events: [InputEventSpec]) -> [InputEventSpec] { events }
    public static func buildOptional(_ event: [InputEventSpec]?) -> [InputEventSpec] { event ?? [] }
    public static func buildEither(first: [InputEventSpec]) -> [InputEventSpec] { first }
    public static func buildEither(second: [InputEventSpec]) -> [InputEventSpec] { second }
    public static func buildArray(_ arr: [[InputEventSpec]]) -> [InputEventSpec] { arr.flatMap { $0 } }
}
