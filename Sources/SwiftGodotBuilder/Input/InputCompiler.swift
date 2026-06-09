import SwiftGodot

struct InputCompiler {
    // MARK: Variables
    let kind: Kind
    let phases: BitSet<InputPhase>
    let acceptEcho: Bool
    // MARK: Methods
    static func compile(_ parts: [InputMatch]) -> InputCompiler {
        var kind: Kind = .any
        var phases: BitSet<InputPhase> = []
        var acceptEcho = false

        for match in parts {
            switch match {
                case .any: kind = .any
                case .phase(.pressed): phases.insert(.only(.pressed))
                case .phase(.released): phases.insert(.only(.released))
                case .phase(.echo): acceptEcho = true
                case let .key(key): kind = .key(key)
                case let .mouse(button): kind = .mouse(button)
                case let .joyButton(button): kind = .joy(button)
                case let .action(name): kind = .action(StringName(name))
            }
        }

        if phases.isEmpty { phases = [.pressed] }

        return .init(kind: kind, phases: phases, acceptEcho: acceptEcho)
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
