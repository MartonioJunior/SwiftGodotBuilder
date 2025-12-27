import SwiftGodot

public extension GNode where T: Node {
  /// Registers a closure to be called when the node is ready.
  ///
  /// ### Usage:
  /// ```swift
  /// Node2D$()
  ///   .onReady { node in
  ///     // Do something with `node`
  ///   }
  /// ```
  func onReady(_ body: @escaping (T) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onReady: body) }
    return s
  }

  /// Registers a closure to be called every frame during the node's process step.
  ///
  /// ### Usage:
  /// ```swift
  /// Node2D$()
  ///   .onProcess { node, delta in
  ///     // Do something with `node` and `delta`
  ///   }
  /// ```
  func onProcess(_ body: @escaping (T, Double) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onProcess: body) }
    return s
  }

  /// Registers a closure to be called every frame during the node's physics process step.
  ///
  /// ### Usage:
  /// ```swift
  /// Node2D$()
  ///   .onPhysicsProcess { node, delta in
  ///     // Do something with `node` and `delta`
  ///   }
  /// ```
  func onPhysicsProcess(_ body: @escaping (T, Double) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onPhysics: body) }
    return s
  }

  /// Registers a closure to be called when the node exits the scene tree.
  ///
  /// ### Usage:
  /// ```swift
  /// Node2D$()
  ///   .onExitTree { node in
  ///     // Clean up resources
  ///   }
  /// ```
  func onExitTree(_ body: @escaping (T) -> Void) -> Self {
    var s = self
    s.ops.append { host in _attachOrUpdateRelay(host, onExitTree: body) }
    return s
  }

  /// Captures a reference to the node when it's ready.
  ///
  /// ### Usage:
  /// ```swift
  /// @State var playerNode: CharacterBody2D?
  ///
  /// CharacterBody2D$()
  ///   .ref($playerNode)
  /// ```
  ///
  /// Equivalent to:
  /// ```swift
  /// .onReady { node in
  ///   playerNode = node
  /// }
  /// ```
  func ref(_ binding: GState<T?>) -> Self {
    onReady { node in
      binding.wrappedValue = node
    }
  }

  /// Syncs a node property to a value each frame during `_process`.
  ///
  /// Use this for lightweight reactivity with plain objects (no @Observable overhead).
  ///
  /// ### Usage:
  /// ```swift
  /// Line2D$()
  ///   .sync(\.visible) { state.isSelected }
  /// ```
  func sync<V: Equatable>(_ nodeKeyPath: ReferenceWritableKeyPath<T, V>, _ value: @escaping () -> V) -> Self {
    var lastValue: V?
    return onProcess { node, _ in
      let newValue = value()
      if lastValue != newValue {
        node[keyPath: nodeKeyPath] = newValue
        lastValue = newValue
      }
    }
  }

}

private func _attachOrUpdateRelay<T: Node>(
  _ host: T,
  onReady: ((T) -> Void)? = nil,
  onProcess: ((T, Double) -> Void)? = nil,
  onPhysics: ((T, Double) -> Void)? = nil,
  onExitTree: ((T) -> Void)? = nil
) {
  let relay: GProcessRelay = {
    // Use getNodeOrNull to avoid triggering the typed array resolution
    // which causes "Unknown class name: Node." error in barebone-split branch
    if let existing = host.getNodeOrNull(path: NodePath("__GProcessRelay__")) as? GProcessRelay {
      return existing
    }

    let r = GProcessRelay()
    r.name = StringName("__GProcessRelay__")
    r.ownerNode = .init(host)
    host.addChild(node: r)
    return r
  }()

  if let onReady {
    let prev = relay.onReadyCall
    relay.onReadyCall = { [weak host] n in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n)
      onReady(typed)
    }
  }
  if let onProcess {
    let prev = relay.onProcessCall
    relay.onProcessCall = { [weak host] (n: Node, dt: Double) in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n, dt)
      onProcess(typed, dt)
    }
    relay.setProcess(enable: true)
  }
  if let onPhysics {
    let prev = relay.onPhysicsCall
    relay.onPhysicsCall = { [weak host] (n: Node, dt: Double) in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n, dt)
      onPhysics(typed, dt)
    }
    relay.setPhysicsProcess(enable: true)
  }
  if let onExitTree {
    let prev = relay.onExitTreeCall
    relay.onExitTreeCall = { [weak host] n in
      guard let typed = host ?? (n as? T) else { return }
      prev?(n)
      onExitTree(typed)
    }
  }
}
