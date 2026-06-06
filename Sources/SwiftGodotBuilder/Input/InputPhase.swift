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
    public static let pressed = InputPhase(rawValue: 1 << 0)
    public static let released = InputPhase(rawValue: 1 << 1)
    public static let echo = InputPhase(rawValue: 1 << 2)
}
