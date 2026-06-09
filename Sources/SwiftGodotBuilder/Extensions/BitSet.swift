//
//  BitSet.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 08/06/2026.
//

/// Collection that represents a set of boolean flags.
public struct BitSet<Base: RawRepresentable> where Base.RawValue == Int {
    // MARK: Variables
    public var rawValue: Int
    // MARK: Initializers
    public init(rawValue: Int = .zero) {
        self.rawValue = rawValue
    }
}

// MARK: DotSyntax
public extension BitSet {
    static var all: Self { .init(rawValue: .max) }

    static func only(_ flag: Base) -> Self {
        .init(rawValue: rawValue(for: flag))
    }

    static func rawValue(for flag: Base) -> Int {
        1 << flag.rawValue
    }
}

// MARK: Self: ExpressibleByArrayLiteral
extension BitSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Base...) {
        self.init()
        for element in elements {
            rawValue |= Self.rawValue(for: element)
        }
    }
}

// MARK: Self: OptionSet
extension BitSet: OptionSet {}

// MARK: Self: RawRepresentable
extension BitSet: RawRepresentable {}
