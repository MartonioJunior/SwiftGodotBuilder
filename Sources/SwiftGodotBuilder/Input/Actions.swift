import SwiftGodot
/// Top-level container for a set of actions to be installed into `InputMap`.
///
/// ### Usage:
/// ```swift
/// let inputs = Actions {
///   Action("jump") { Key(.space) }
///   Action("shoot") { MouseButton(1) }
/// }
/// inputs.install(clearExisting: true)
/// ```
public struct Actions {
    // MARK: Variables
    /// The actions to be installed.
    public let actions: [ActionSpec]
    // MARK: Initializers
    /// Builds an `Actions` from a declarative block of `ActionSpec`s.
    public init(@ActionBuilder _ content: () -> [ActionSpec]) {
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

// MARK: - Recipes
/// Ready-made helpers that expand into multiple `ActionSpec`s for common patterns.
/// Useful for mapping analog axes to paired digital actions (e.g. up/down, left/right).
public enum ActionRecipes {
    /// Produces `<prefix>_down` and `<prefix>_up` actions for a vertical axis.
    ///
    /// Each action includes the axis motion plus any optional key or button,
    /// with a shared deadzone applied to both.
    ///
    /// - Parameters:
    ///   - namePrefix: Action name prefix, e.g. `"move"` -> `"move_down"`, `"move_up"`.
    ///   - device: Joypad device index.
    ///   - axis: The joypad axis to sample.
    ///   - deadzone: Deadzone for both actions (default `0.2`).
    ///   - keyDown: Optional keyboard keys to include.
    ///   - keyUp: Optional keyboard keys to include.
    ///   - btnDown: Optional joypad buttons to include.
    ///   - btnUp: Optional joypad buttons to include.
    /// - Returns: Two `ActionSpec`s: `*_down` (value `+1.0`) and `*_up` (value `-1.0`).
    @inlinable public static func axisUD(
        namePrefix: String,
        device: InputDevice,
        axis: JoyAxis,
        deadzone: Double = 0.2,
        keyDown: Key? = nil, keyUp: Key? = nil,
        btnDown: JoyButton? = nil, btnUp: JoyButton? = nil
    ) -> [ActionSpec] {
        let downEv: [InputEventSpec] = [
            .joyAxis(axis: axis, device: device, value: 1.0),
            keyDown.map { .key($0) },
            btnDown.map { .joyButton(button: $0, device: device) }
        ].compactMap { $0 }

        let upEv: [InputEventSpec] = [
            .joyAxis(axis: axis, device: device, value: -1.0),
            keyUp.map { .key($0) },
            btnUp.map { .joyButton(button: $0, device: device) }
        ].compactMap { $0 }

        return [
            ActionSpec("\(namePrefix)_down", deadzone: deadzone, events: downEv),
            ActionSpec("\(namePrefix)_up", deadzone: deadzone, events: upEv)
        ]
    }
    /// Produces `<prefix>_left` and `<prefix>_right` actions for a horizontal axis.
    ///
    /// Mirrors `axisUD` but with left/right semantics and axis values `−1.0/ +1.0`.
    @inlinable public static func axisLR(
        namePrefix: String,
        device: InputDevice,
        axis: JoyAxis,
        deadzone: Double = 0.2,
        keyLeft: Key? = nil,
        keyRight: Key? = nil,
        btnLeft: JoyButton? = nil,
        btnRight: JoyButton? = nil
    ) -> [ActionSpec] {
        let left: [InputEventSpec] = [
            .joyAxis(axis: axis, device: device, value: -1.0),
            keyLeft.map { .key($0) },
            btnLeft.map { .joyButton(button: $0, device: device) }
        ].compactMap { $0 }

        let right: [InputEventSpec] = [
            .joyAxis(axis: axis, device: device, value: 1.0),
            keyRight.map { .key($0) },
            btnRight.map { .joyButton(button: $0, device: device) }
        ].compactMap { $0 }

        return [
            ActionSpec("\(namePrefix)_left", deadzone: deadzone, events: left),
            ActionSpec("\(namePrefix)_right", deadzone: deadzone, events: right)
        ]
    }
}
