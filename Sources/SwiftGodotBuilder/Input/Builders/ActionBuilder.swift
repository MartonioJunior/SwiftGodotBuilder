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
    public static func buildBlock(_ parts: [ActionBinding]...) -> [ActionBinding] { parts.flatMap { $0 } }
    public static func buildExpression(_ action: ActionBinding) -> [ActionBinding] { [action] }
    public static func buildExpression(_ asv: [ActionBinding]) -> [ActionBinding] { asv }
    public static func buildOptional(_ action: [ActionBinding]?) -> [ActionBinding] { action ?? [] }
    public static func buildEither(first: [ActionBinding]) -> [ActionBinding] { first }
    public static func buildEither(second: [ActionBinding]) -> [ActionBinding] { second }
    public static func buildArray(_ arr: [[ActionBinding]]) -> [ActionBinding] { arr.flatMap { $0 } }
}
