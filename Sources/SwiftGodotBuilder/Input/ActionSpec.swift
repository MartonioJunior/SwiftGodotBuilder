import SwiftGodot
/// A named input action and the set of events that trigger it.
///
/// Use `installing(clearExisting:)` to register this action with `InputMap`.
public struct ActionSpec {
    // MARK: Variables
    /// Action name as used by Godot's `InputMap` and `Input.is_action_*` APIs.
    public let name: String
    /// Optional deadzone to apply to the action (commonly for analog axes).
    public let deadzone: Double?
    /// Events (keys, buttons, axes, mouse) that will trigger this action.
    public let events: [InputEvent]
    // MARK: Initializers
    /// Creates a new `ActionSpec`.
    public init(_ name: String, deadzone: Double? = nil, events: [InputEvent]) {
        self.name = name
        self.deadzone = deadzone
        self.events = events
    }
    // MARK: Methods
    /// Registers this action and its events with Godot's `InputMap`.
    ///
    /// - Parameter clearExisting: If `true`, erases any existing events
    ///   for this action before adding the new ones.
    public func installing(clearExisting: Bool = false) {
        let actionName = StringName(name)

        if !InputMap.hasAction(actionName) {
            InputMap.addAction(actionName)
        }

        if let deadzone {
            InputMap.actionSetDeadzone(action: actionName, deadzone: deadzone)
        }

        if clearExisting {
            InputMap.actionEraseEvents(action: actionName)
        }

        for event in events {
            InputMap.actionAddEvent(action: actionName, event: event)
        }
    }
}

// MARK: - Sugar for event literals inside InputEventBuilder
/// Convenience function for building a single `ActionSpec` with an `InputEventBuilder` block.
///
/// ### Usage:
/// ```swift
/// Action("move_left", deadzone: 0.2) {
///   JoyAxis(0, .leftX, -1)
///   Key(.a)
/// }
/// ```
@inlinable public func Action(
    _ name: String,
    deadzone: Double? = nil,
    @InputEventBuilder events: () -> [InputEvent]
) -> ActionSpec {
    ActionSpec(name, deadzone: deadzone, events: events())
}

// MARK: RuntimeAction (EX)
public extension RuntimeAction {
    func binding(
        deadzone: Double? = nil,
        @InputEventBuilder _ events: () -> [InputEvent]
    ) -> ActionSpec {
        .init(action.description, deadzone: deadzone, events: events())
    }
}

// MARK: RuntimeAxisAction (EX)
public extension RuntimeAxisAction {
    func binding(
        deadzone: Double = 0.2,
        @InputEventBuilder negative negativeEvents: () -> [InputEvent],
        @InputEventBuilder positive positiveEvents: () -> [InputEvent]
    ) -> [ActionSpec] {
        let negativeBinding = negativeAction.binding(deadzone: deadzone, negativeEvents)
        let positiveBinding = positiveAction.binding(deadzone: deadzone, positiveEvents)
        return [negativeBinding, positiveBinding]
    }
    /// Performs a binding with a set of related input mechanics.
    /// 
    /// Useful for mapping analog axes to paired digital actions (e.g. up/down, left/right).
    /// Each action includes the axis motion plus any optional key or button,
    /// with a shared deadzone applied to both.
    ///
    /// - Parameters:
    ///   - device: Joypad device index.
    ///   - axis: The joypad axis to sample.
    ///   - deadzone: Deadzone for both actions (default `0.2`).
    ///   - keyNegative: Optional keyboard keys to include.
    ///   - keyPositive: Optional keyboard keys to include.
    ///   - buttonNegative: Optional joypad buttons to include.
    ///   - buttonPositive: Optional joypad buttons to include.
    /// - Returns: An `RuntimeAxisAction`: positive `+1.0` and negative `-1.0` on `axis`.
    func binding(
        device: InputDevice,
        axis: JoyAxis,
        deadzone: Double = 0.2,
        keyNegative: Key? = nil, keyPositive: Key? = nil,
        buttonNegative: JoyButton? = nil, buttonPositive: JoyButton? = nil
    ) -> [ActionSpec] {
        binding(deadzone: deadzone) {
            .combined(device: device, axis: (axis, -1.0), key: keyNegative, button: buttonNegative)
        } positive: {
            .combined(device: device, axis: (axis, 1.0), key: keyPositive, button: buttonPositive)
        }
    }
}
