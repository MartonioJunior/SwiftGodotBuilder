/// Result builder for composing `[ActionSpec]` in a DSL block.
///
/// Enables:
/// ```swift
/// Actions {
///   Action("fire") { MouseButton(1) }
///   Action("left") { Key(.a) }
///   Action("right") { Key(.d) }
/// }
/// ```
@_documentation(visibility: private)
@resultBuilder
public enum ActionBuilder {
    public static func buildBlock(_ parts: [ActionSpec]...) -> [ActionSpec] { parts.flatMap { $0 } }
    public static func buildExpression(_ action: ActionSpec) -> [ActionSpec] { [action] }
    public static func buildExpression(_ asv: [ActionSpec]) -> [ActionSpec] { asv }
    public static func buildOptional(_ action: [ActionSpec]?) -> [ActionSpec] { action ?? [] }
    public static func buildEither(first: [ActionSpec]) -> [ActionSpec] { first }
    public static func buildEither(second: [ActionSpec]) -> [ActionSpec] { second }
    public static func buildArray(_ arr: [[ActionSpec]]) -> [ActionSpec] { arr.flatMap { $0 } }
}
