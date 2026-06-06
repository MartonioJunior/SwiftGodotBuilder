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
    // MARK: Methods
    /// Returns the axis value for paired actions (e.g., "left"/"right").
    ///
    /// Typically used with action pairs like `move_left`/`move_right` to get
    /// a signed axis value (-1.0 to 1.0).
    ///
    /// - Parameters:
    ///   - negative: Action name for negative direction
    ///   - positive: Action name for positive direction
    @inlinable public static func axis(
        negative: String,
        positive: String
    ) -> Double {
        Input.getAxis(
        negativeAction: StringName(negative),
        positiveAction: StringName(positive)
        )
    }
    /// Returns the 2D vector for paired action sets (e.g., movement).
    ///
    /// Combines horizontal and vertical action pairs into a normalized
    /// `Vector2` suitable for 2D movement.
    ///
    /// - Parameters:
    ///   - negativeX: Action name for left/negative-x
    ///   - positiveX: Action name for right/positive-x
    ///   - negativeY: Action name for up/negative-y
    ///   - positiveY: Action name for down/positive-y
    ///   - deadzone: Optional deadzone override (default -1.0 uses InputMap value)
    @inlinable public static func vector(
        negativeX: String,
        positiveX: String,
        negativeY: String,
        positiveY: String,
        deadzone: Double = -1.0
    ) -> Vector2 {
        Input.getVector(
        negativeX: StringName(negativeX),
        positiveX: StringName(positiveX),
        negativeY: StringName(negativeY),
        positiveY: StringName(positiveY),
        deadzone: deadzone
        )
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
