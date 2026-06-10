import SwiftGodot
/// Top-level container for a set of actions to be installed into `InputMap`.
///
/// ### Usage:
/// ```swift
/// let inputs = Actions {
///   ActionBinding("jump") { Keyboard.key(.space) }
///   ActionBinding("shoot") { Mouse.button(1) }
/// }
/// inputs.install(clearExisting: true)
/// ```
public struct Actions {
    // MARK: Variables
    /// The actions to be installed.
    public let actions: [ActionBinding]
    // MARK: Initializers
    /// Builds an `Actions` from a declarative block of `ActionSpec`s.
    public init(@ActionBuilder _ content: () -> [ActionBinding]) {
        actions = content()
    }
    // MARK: Methods
    /// Installs all actions into the `InputMap` in declaration order.
    ///
    /// - Parameter clearExisting: When `true`, purges existing events for each
    ///   action name before re-adding the declared bindings.
    public func install(clearExisting: Bool = false) {
        for action in actions {
            action.installing(clearExisting: clearExisting)
        }
    }
}
