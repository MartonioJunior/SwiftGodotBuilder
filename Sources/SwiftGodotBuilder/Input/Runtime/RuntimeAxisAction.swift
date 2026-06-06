//
//  RuntimeAxisAction.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

import SwiftGodot

/// A runtime wrapper for querying the state of two input actions in an axis.
/// 
/// Typically used with action pairs like `move_left`/`move_right` to get
/// a signed axis value (-1.0 to 1.0).
public struct RuntimeAxisAction {
    // MARK: Variables
    /// Action for negative direction.
    public let negativeAction: RuntimeAction
    /// Action for positive direction.
    public let positiveAction: RuntimeAction
    // MARK: Initializers
    /// Creates a runtime axis query for the given actions.
    /// - Parameters:
    ///   - negative: Action for negative direction
    ///   - positive: Action for positive direction
    ///
    public init(negative: RuntimeAction, positive: RuntimeAction) {
        negativeAction = Action(negative)
        positiveAction = Action(positive)
    }
}

// MARK: Self: GodotInputAction
extension RuntimeAxisAction: GodotInputAction {
    @inlinable public var isPressed: Bool {
        negativeAction.isPressed || positiveAction.isPressed
    }

    @inlinable public var isJustPressed: Bool {
        negativeAction.isJustPressed || positiveAction.isJustPressed
    }

    @inlinable public var isJustReleased: Bool {
        negativeAction.isJustReleased || positiveAction.isJustReleased
    }

    @inlinable public var strength: Double {
        Input.getAxis(
            negativeAction: negativeAction.action,
            positiveAction: positiveAction.action
        )
    }

    @inlinable public var rawStrength: Double {
        Input.getActionRawStrength(action: positiveAction.action)
        - Input.getActionRawStrength(action: negativeAction.action)
    }
}

// MARK: GodotInputAction (EX)
public extension GodotInputAction where Self == RuntimeAxisAction {
    /// Returns the axis value for paired actions (e.g., "left"/"right").
    ///
    /// Typically used with action pairs like `move_left`/`move_right` to get
    /// a signed axis value (-1.0 to 1.0).
    ///
    /// - Parameters:
    ///   - negative: Action for negative direction
    ///   - positive: Action for positive direction
    @inlinable static func axis(
        negative: RuntimeAction,
        positive: RuntimeAction
    ) -> Self {
        .init(
            negative: .init(negative),
            positive: .init(positive)
        )
    }
}
