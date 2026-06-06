//
//  RuntimeVector2Action.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

public struct RuntimeVector2Action {
    // MARK: Variables
    /// Composite action for the X axis.
    var x: RuntimeAxisAction
    /// Composite action for the Y axis.
    var y: RuntimeAxisAction
    /// Deadzone for the vector.
    var deadzone: Double
    // MARK: Initializers
    /// Creates a runtime vector query for the given axis actions.
    /// - Parameters:
    ///   - x: Action for the X axis.
    ///   - y: Action for the Y axis.
    ///   - deadzone: Deadzone value (default -1.0 uses InputMap value)
    public init(
        x: RuntimeAxisAction,
        y: RuntimeAxisAction,
        deadzone: Double = -1.0
    ) {
        self.x = x
        self.y = y
        self.deadzone = deadzone
    }
}

// MARK: Self: GodotInputAction
extension RuntimeVector2Action: GodotInputAction {
    @inlinable public var isPressed: Bool {
        x.isPressed || y.isPressed
    }

    @inlinable public var isJustPressed: Bool {
        x.isJustPressed || y.isJustPressed
    }

    @inlinable public var isJustReleased: Bool {
        x.isJustReleased || y.isJustReleased
    }

    @inlinable public var strength: Vector2 {
        Input.getVector(
            negativeX: x.negative.action,
            positiveX: x.positive.action,
            negativeY: y.negative.action,
            positiveY: y.positive.action,
            deadzone: deadzone
        )
    }

    @inlinable public var rawStrength: Vector2 {
        Vector2(
            x: x.rawStrength,
            y: y.rawStrength
        )
    }
}

// MARK: GodotInputAction (EX)
public extension GodotInputAction where Self == RuntimeVector2Action {
    /// Returns the 2D vector for paired action sets (e.g., movement).
    ///
    /// Combines horizontal and vertical action pairs into a normalized
    /// `Vector2` suitable for 2D movement.
    ///
    /// - Parameters:
    ///   - negativeX: Action for left/negative-x
    ///   - positiveX: Action for right/positive-x
    ///   - negativeY: Action for up/negative-y
    ///   - positiveY: Action for down/positive-y
    ///   - deadzone: Optional deadzone override (default -1.0 uses InputMap value)
    @inlinable public static func vector(
        negativeX: RuntimeAction,
        positiveX: RuntimeAction,
        negativeY: RuntimeAction,
        positiveY: RuntimeAction,
        deadzone: Double = -1.0
    ) -> Self {
        .init(
            x: .axis(negative: negativeX, positive: positiveX),
            y: .axis(negative: negativeY, positive: positiveY),
            deadzone: deadzone
        )
    }
}
