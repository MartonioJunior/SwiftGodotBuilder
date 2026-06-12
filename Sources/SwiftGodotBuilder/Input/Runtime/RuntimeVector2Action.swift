//
//  RuntimeVector2Action.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

/// A runtime wrapper for querying the state of two axises.
///
/// Combines horizontal and vertical action pairs into a normalized
/// `Vector2` suitable for 2D movement.
public struct RuntimeVector2Action {
    // MARK: Variables
    /// Composite action for the X axis.
    public let x: RuntimeAxisAction
    /// Composite action for the Y axis.
    public let y: RuntimeAxisAction
    /// Deadzone for the vector.
    public var deadzone: Double?
    // MARK: Initializers
    /// Creates a runtime vector query for the given axis actions.
    /// - Parameters:
    ///   - x: Action for the X axis.
    ///   - y: Action for the Y axis.
    ///   - deadzone: Deadzone for the vector.
    public init(
        x: RuntimeAxisAction,
        y: RuntimeAxisAction,
        deadzone: Double? = nil
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
            negativeX: x.negativeAction.action,
            positiveX: x.positiveAction.action,
            negativeY: y.negativeAction.action,
            positiveY: y.positiveAction.action,
            deadzone: deadzone ?? -1.0 // default -1.0 uses InputMap value
        )
    }

    @inlinable public var rawStrength: Vector2 {
        Vector2(
            x: Float(x.rawStrength),
            y: Float(y.rawStrength)
        )
    }
}

// MARK: GodotInputAction (EX)
public extension GodotInputAction where Self == RuntimeVector2Action {
    /// Produces a vector with up, down, left and right actions.
    /// - Parameter prefix: Prefix name for the actions.
    /// - Returns: A new 2D vector action.
    static func directional(prefix: String) -> Self {
        .init(x: .leftRight(prefix: prefix), y: .upDown(prefix: prefix))
    }
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
    ///   - deadzone: Deadzone for the vector.
    @inlinable static func vector(
        negativeX: RuntimeAction,
        positiveX: RuntimeAction,
        negativeY: RuntimeAction,
        positiveY: RuntimeAction,
        deadzone: Double? = nil
    ) -> Self {
        .init(
            x: .axis(negative: negativeX, positive: positiveX),
            y: .axis(negative: negativeY, positive: positiveY),
            deadzone: deadzone
        )
    }
}
