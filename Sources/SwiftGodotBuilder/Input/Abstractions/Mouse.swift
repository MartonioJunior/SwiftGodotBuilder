//
//  Mouse.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 07/06/2026.
//

import SwiftGodot

/// Abstraction that represents a mouse or a pen device.
public struct Mouse {
    /// Creates an input event for a mouse button.
    /// - Parameter button: Mouse button to be used.
    /// - Returns: `InputEventMouseButton` for `button`.
    static func button(_ button: Button) -> InputEventMouseButton {
        .init(button)
    }
}

// MARK: Self.Button
public extension Mouse {
    typealias Button = MouseButton
}

// MARK: Self.Input
public extension Mouse {
    enum Input {
        case button(MouseButton)
        case movement(Movement)
    }
}

// MARK: Self.Movement
public extension Mouse {
    struct Movement {
        var local: Info = .init()
        var global: Info = .init()
    }
}

public extension Mouse.Movement {
    struct Info {
        var delta: Vector2 = .zero
        var position: Vector2 = .zero
        var velocity: Vector2 = .zero
    }
}

// MARK: Self: InputSource
extension Mouse: InputSource {
    public var device: InputDevice { 32 }

    public static func unwrapEvent(_ event: InputEvent) -> Input? {
        switch event {
            case let mouseButtonEvent as InputEventMouseButton:
                .button(mouseButtonEvent.buttonIndex)
            case let mouseMotionEvent as InputEventMouseMotion:
                .movement(mouseMotionEvent.fullMovement)
            default:
                nil
        }
    }

    public func wrapInput(_ input: Input) -> InputEvent {
        switch input {
            case let .button(button):
                InputEventMouseButton(button)
            case let .movement(movement):
                InputEventMouseMotion().withMovement(movement)
        }
    }
}

// MARK: InputEventMouseMotion (EX)
public extension InputEventMouseMotion {
    var fullMovement: Mouse.Movement {
        .init(
            local: .init(
                delta: relative,
                position: position,
                velocity: velocity
            ),
            global: .init(
                delta: screenRelative,
                position: globalPosition,
                velocity: screenVelocity
            ),
        )
    }

    @discardableResult
    func withMovement(_ movement: Mouse.Movement) -> Self {
        self.relative = movement.local.delta
        self.position = movement.local.position
        self.velocity = movement.local.velocity
        self.screenRelative = movement.global.delta
        self.globalPosition = movement.global.position
        self.screenVelocity = movement.global.velocity
        return self
    }
}
