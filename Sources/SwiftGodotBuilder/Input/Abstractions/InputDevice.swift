//
//  InputDevice.swift
//  SwiftGodotBuilder
//
//  Created by Martônio Júnior on 06/06/2026.
//

/// Abstraction that represents information about an input device.
public struct InputDevice {
    /// Identifier for the device used.
    /// 
    /// Can be negative for special use cases that don't refer to devices physically present on the system.
    public var id: Int
    /// Is the device emulated?
    public var isEmulated: Bool { id < 0 }
    /// Creates a new input device.
    /// - Parameter id: Identifier for the device.
    public init(_ id: Int) {
        self.id = id
    }
}

// MARK: Self: ExpressibleByIntegerLiteral
extension InputDevice: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.id = value
    }
}

// MARK: Self: Identifiable
extension InputDevice: Identifiable {}
