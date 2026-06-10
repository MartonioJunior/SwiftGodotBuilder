/// Result builder for composing `[ActionBinding]` in a DSL block.
///
/// Enables:
/// ```swift
/// ActionSet {
///   ActionBinding("fire") { MouseButton(1) }
///   ActionBinding("left") { Key(.a) }
///   ActionBinding("right") { Key(.d) }
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
