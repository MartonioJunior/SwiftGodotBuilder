import SwiftGodot

/// Register multiple types with Godot.
/// - Parameter types: An array of types to register.
/// ### Usage:
/// ```swift
/// register(types: [MyNode.self, MyOtherNode.self])
/// ```
/// Replaces:
/// ```swift
/// register(type: MyNode.self)
/// register(type: MyOtherNode.self)
/// ```
public func register(types: [Object.Type]) {
  for t in types {
    register(type: t)
  }
}
