public struct InputPhase: OptionSet, Sendable {
    // MARK: Variables
    public let rawValue: Int
    // MARK: Initializers
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

// MARK: DotSyntax
public extension InputPhase {
    static let pressed = InputPhase(rawValue: 1 << 0)
    static let released = InputPhase(rawValue: 1 << 1)
    static let echo = InputPhase(rawValue: 1 << 2)
}
