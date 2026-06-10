//
//  InputSource.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 10/06/2026.
//

import SwiftGodot

public protocol InputSource {
    /// Type of input events that can be received.
    associatedtype Input
    /// Device associated with the input.
    var device: InputDevice { get }
    // MARK: Methods
    /// Attempts to extracts information from an input event instance.
    static func unwrapEvent(_ event: InputEvent) -> Input?
    /// Builds the corresponding Godot `InputEvent` instance.
    ///
    /// This materializes the declarative spec into an engine object that
    /// can be registered with `InputMap`.
    func wrapInput(_ input: Input) -> InputEvent
}

// MARK: Default Implementation
public extension InputSource {
    func unwrapEvent(_ event: InputEvent) -> Input? {
        guard event.device == device.id else { return nil }

        return Self.unwrapEvent(event)
    }

    func validate(
        _ event: InputEvent,
        mask: BitSet<InputPhase> = .all,
        predicate: (Input) -> Bool
    ) -> Bool {
        guard event.device == device.id, let input = unwrapEvent(event) else { return false }

        let validInput = predicate(input)

        return validInput && mask.validate(event)
    }
}
