import SwiftGodot
/// A runtime wrapper for querying the state of an input action.
///
/// Caches the `StringName` to avoid repeated allocations when polling
/// input state each frame. Access via the `Action(_:)` function or
/// `Actions[_:]` subscript.
///
/// ### Usage:
/// ```swift
/// // In your _process or handleInput:
/// if Action("jump").isJustPressed {
///   player.jump()
/// }
///
/// if Action("move_left").isPressed {
///   player.moveLeft(Action("move_left").strength)
/// }
///
/// // Or via subscript:
/// if Actions["pause"].isJustPressed {
///   togglePause()
/// }
/// ```
public struct RuntimeAction {
    // MARK: Variables
    /// The action name as a cached `StringName`.
    public let action: StringName
    // MARK: Initializers
    /// Creates a runtime action query for the given action name.
    ///
    /// The `StringName` is created once and cached, so repeated calls
    /// to the same action are efficient.
    public init(name: String) {
        action = StringName(name)
    }
}
/// Returns a `RuntimeAction` for querying the state of an input action.
///
/// This function provides a clean API for checking action state at runtime
/// without repeatedly constructing `StringName` objects.
///
/// ### Usage:
/// ```swift
/// if Action("jump").isJustPressed {
///   player.jump()
/// }
///
/// let moveSpeed = Action("run").strength * baseSpeed
/// ```
///
/// Note: This overload is distinct from the `Action(_:deadzone:events:)`
/// function used for declaring actions. That version requires the `events`
/// builder parameter.
@inlinable public func Action(_ name: String) -> RuntimeAction {
    RuntimeAction(name: name)
}

// MARK: Self: ExpressibleByStringLiteral
extension RuntimeAction: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

// MARK: Self: GodotInputAction
extension RuntimeAction: GodotInputAction {
    @inlinable public var isPressed: Bool {
        Input.isActionPressed(action: action)
    }

    @inlinable public var isJustPressed: Bool {
        Input.isActionJustPressed(action: action)
    }

    @inlinable public var isJustReleased: Bool {
        Input.isActionJustReleased(action: action)
    }
    /// Returns the analog strength of the action (0.0 to 1.0).
    ///
    /// For digital inputs, returns `1.0` when pressed, `0.0` otherwise.
    /// For analog inputs (axes), returns the current value after deadzone.
    @inlinable public var strength: Double {
        Input.getActionStrength(action: action)
    }
    /// Returns the raw analog strength without deadzone processing.
    @inlinable public var rawStrength: Double {
        Input.getActionRawStrength(action: action)
    }
}
