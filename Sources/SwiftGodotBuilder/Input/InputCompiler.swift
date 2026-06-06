import SwiftGodot

struct InputCompiler {
    // MARK: Variables
    let kind: Kind
    let phases: InputPhase
    let acceptEcho: Bool
    // MARK: Methods
    static func compile(_ parts: [InputMatch]) -> InputCompiler {
        var kind: Kind = .any
        var phases: InputPhase = []
        var acceptEcho = false

        for match in parts {
            switch match {
                case .any: kind = .any
                case .pressed: phases.insert(.pressed)
                case .released: phases.insert(.released)
                case .echo: acceptEcho = true
                case let .key(key): kind = .key(key)
                case let .mouse(button): kind = .mouse(button)
                case let .joyButton(button): kind = .joy(button)
                case let .action(name): kind = .action(StringName(name))
            }
        }

        if phases.isEmpty { phases = [.pressed] }

        return .init(kind: kind, phases: phases, acceptEcho: acceptEcho)
    }

    func matches(_ event: InputEvent) -> Bool {
        switch kind {
            case .any:
                return matchesPhase(event)
            case let .key(key):
                guard let kev = event as? InputEventKey, kev.physicalKeycode == key else { return false }
                return matchesKeyPhase(kev)
            case let .mouse(button):
                guard let mev = event as? InputEventMouseButton, mev.buttonIndex == button else { return false }
                return matchesMousePhase(mev)
            case let .joy(button):
                guard let jev = event as? InputEventJoypadButton, jev.buttonIndex == button else { return false }
                return matchesButtonPhase(jev.pressed)
            case let .action(name):
                if phases.contains(.pressed), event.isActionPressed(action: name) { return true }
                if phases.contains(.released), event.isActionReleased(action: name) { return true }
                return false
        }
    }

    private func matchesPhase(_ event: InputEvent) -> Bool {
        if let kev = event as? InputEventKey { return matchesKeyPhase(kev) }
        if let mev = event as? InputEventMouseButton { return matchesMousePhase(mev) }
        if let btn = event as? InputEventJoypadButton { return matchesButtonPhase(btn.pressed) }

        return false
    }

    private func matchesKeyPhase(_ kev: InputEventKey) -> Bool {
        if kev.echo { return acceptEcho }

        return kev.pressed ? phases.contains(.pressed) : phases.contains(.released)
    }

    private func matchesMousePhase(_ mev: InputEventMouseButton) -> Bool {
        return mev.pressed ? phases.contains(.pressed) : phases.contains(.released)
    }

    private func matchesButtonPhase(_ pressed: Bool) -> Bool {
        return pressed ? phases.contains(.pressed) : phases.contains(.released)
    }
}

// MARK: Self.Kind
extension InputCompiler {
    enum Kind {
        case any
        case key(Key)
        case mouse(MouseButton)
        case joy(JoyButton)
        case action(StringName)
    }
}
