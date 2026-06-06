import SwiftGodot

struct _CompiledFilter {
    // MARK: Variables
    let kind: Kind
    let phases: InputPhase
    let acceptEcho: Bool
    // MARK: Methods
    static func compile(_ parts: [InputMatch]) -> _CompiledFilter {
        var kind: Kind = .any
        var phases: InputPhase = []
        var acceptEcho = false

        for p in parts {
            switch p {
                case .any: kind = .any
                case .pressed: phases.insert(.pressed)
                case .released: phases.insert(.released)
                case .echo: acceptEcho = true
                case let .key(k): kind = .key(k)
                case let .mouse(b): kind = .mouse(b)
                case let .joyButton(b): kind = .joy(b)
                case let .action(name): kind = .action(StringName(name))
            }
        }

        if phases.isEmpty { phases = [.pressed] }

        return .init(kind: kind, phases: phases, acceptEcho: acceptEcho)
    }

    func matches(_ ev: InputEvent) -> Bool {
        switch kind {
            case .any:
                return matchesPhase(ev)
            case let .key(k):
                guard let kev = ev as? InputEventKey, kev.physicalKeycode == k else { return false }
                return matchesKeyPhase(kev)
            case let .mouse(b):
                guard let mev = ev as? InputEventMouseButton, mev.buttonIndex == b else { return false }
                return matchesMousePhase(mev)
            case let .joy(b):
                guard let jev = ev as? InputEventJoypadButton, jev.buttonIndex == b else { return false }
                return matchesButtonPhase(jev.pressed)
            case let .action(name):
                if phases.contains(.pressed), ev.isActionPressed(action: name) { return true }
                if phases.contains(.released), ev.isActionReleased(action: name) { return true }
                return false
        }
    }

    private func matchesPhase(_ ev: InputEvent) -> Bool {
        if let kev = ev as? InputEventKey { return matchesKeyPhase(kev) }
        if let mev = ev as? InputEventMouseButton { return matchesMousePhase(mev) }
        if let btn = ev as? InputEventJoypadButton { return matchesButtonPhase(btn.pressed) }

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
extension _CompiledFilter {
    enum Kind {
        case any
        case key(Key)
        case mouse(MouseButton)
        case joy(JoyButton)
        case action(StringName)
    }
}
