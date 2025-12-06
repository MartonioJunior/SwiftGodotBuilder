import SwiftGodot

// MARK: - Dynamic State Binding via subscript

public extension GNode {
  /// Dynamic member lookup for GState binding
  /// Usage: .position($myState) or .scale($myScale)
  subscript<V>(dynamicMember kp: ReferenceWritableKeyPath<T, V>) -> (GState<V>) -> Self {
    { state in
      var s = self
      s.ops.append { node in
        state.observe { [weak node] value in
          guard let node else { return }
          node[keyPath: kp] = value
        }
      }
      return s
    }
  }

  /// Dynamic member lookup for GState binding with transform
  /// Usage: .rotation($playerRotation) { Double($0) }
  subscript<V, U>(dynamicMember kp: ReferenceWritableKeyPath<T, V>) -> (GState<U>, @escaping (U) -> V) -> Self {
    { state, transform in
      var s = self
      s.ops.append { node in
        state.observe { [weak node] value in
          guard let node else { return }
          node[keyPath: kp] = transform(value)
        }
      }
      return s
    }
  }

  /// Dynamic member lookup for GState with transform to StringName
  subscript(dynamicMember kp: ReferenceWritableKeyPath<T, StringName>) -> (GState<String>) -> Self {
    { state in
      var s = self
      s.ops.append { node in
        state.observe { [weak node] value in
          guard let node else { return }
          node[keyPath: kp] = StringName(value)
        }
      }
      return s
    }
  }

  /// Dynamic member lookup for GState with RawRepresentable enum
  subscript<E>(dynamicMember kp: ReferenceWritableKeyPath<T, E>) -> (GState<E.RawValue>) -> Self where E: RawRepresentable {
    { state in
      var s = self
      s.ops.append { node in
        state.observe { [weak node] raw in
          guard let node else { return }
          guard let e = E(rawValue: raw) else {
            GD.printErr("⚠️ Invalid rawValue for \(E.self):", raw)
            return
          }
          node[keyPath: kp] = e
        }
      }
      return s
    }
  }
}

// MARK: - State Binding Extensions for GNode

public extension GNode {
  /// Bind a reactive source to a keyPath, updating the node property whenever it changes
  /// Usage: .bind(\.position, to: $position)
  func bind<V, R: ReactiveSource<V>>(_ kp: ReferenceWritableKeyPath<T, V>, to source: R) -> Self {
    var s = self
    s.ops.append { node in
      source.observe { [weak node] value in
        guard let node else { return }
        node[keyPath: kp] = value
      }
    }
    return s
  }

  /// Bind a reactive source with a transformation function
  /// Usage: .bind(\.text, to: $position) { "\($0.x), \($0.y)" }
  func bind<V, U, R: ReactiveSource<V>>(_ kp: ReferenceWritableKeyPath<T, U>, to source: R, transform: @escaping (V) -> U) -> Self {
    var s = self
    s.ops.append { node in
      source.observe { [weak node] value in
        guard let node else { return }
        node[keyPath: kp] = transform(value)
      }
    }
    return s
  }

  /// Bind a sub-property of a reactive source to a node property
  /// Usage: .bind(\.width, to: $myState, \.x)
  func bind<V, U, R: ReactiveSource<V>>(_ kp: ReferenceWritableKeyPath<T, U>, to source: R, _ sourceKeyPath: KeyPath<V, U>) -> Self {
    var s = self
    s.ops.append { node in
      source.observe { [weak node] value in
        guard let node else { return }
        node[keyPath: kp] = value[keyPath: sourceKeyPath]
      }
    }
    return s
  }

  /// Update node when reactive source changes using a custom closure
  /// Usage: .watch($myState) { node, value in ... }
  func watch<V, R: ReactiveSource<V>>(_ source: R, _ handler: @escaping (T, V) -> Void) -> Self {
    var s = self
    s.ops.append { node in
      source.observe { [weak node] value in
        guard let node else { return }
        handler(node, value)
      }
    }
    return s
  }
}

// MARK: - Multi-State Binding Extensions

public extension GNode {
  /// Bind two GStates with a transformation function
  /// Usage: .bind(\.text, to: $message, $width) { msg, w in "Message: \(msg.count) chars, width: \(w)px" }
  func bind<V1, V2, U>(
    _ kp: ReferenceWritableKeyPath<T, U>,
    to state1: GState<V1>,
    _ state2: GState<V2>,
    transform: @escaping (V1, V2) -> U
  ) -> Self {
    var s = self
    s.ops.append { node in
      let update = { [weak node] in
        guard let node = node else { return }
        node[keyPath: kp] = transform(state1.wrappedValue, state2.wrappedValue)
      }
      state1.observe { _ in update() }
      state2.observe { _ in update() }
    }
    return s
  }

  /// Bind three GStates with a transformation function
  /// Usage: .bind(\.text, to: $a, $b, $c) { a, b, c in "\(a) - \(b) - \(c)" }
  func bind<V1, V2, V3, U>(
    _ kp: ReferenceWritableKeyPath<T, U>,
    to state1: GState<V1>,
    _ state2: GState<V2>,
    _ state3: GState<V3>,
    transform: @escaping (V1, V2, V3) -> U
  ) -> Self {
    var s = self
    s.ops.append { node in
      let update = { [weak node] in
        guard let node = node else { return }
        node[keyPath: kp] = transform(state1.wrappedValue, state2.wrappedValue, state3.wrappedValue)
      }
      state1.observe { _ in update() }
      state2.observe { _ in update() }
      state3.observe { _ in update() }
    }
    return s
  }

  /// Bind four GStates with a transformation function
  /// Usage: .bind(\.text, to: $a, $b, $c, $d) { a, b, c, d in "\(a) - \(b) - \(c) - \(d)" }
  func bind<V1, V2, V3, V4, U>(
    _ kp: ReferenceWritableKeyPath<T, U>,
    to state1: GState<V1>,
    _ state2: GState<V2>,
    _ state3: GState<V3>,
    _ state4: GState<V4>,
    transform: @escaping (V1, V2, V3, V4) -> U
  ) -> Self {
    var s = self
    s.ops.append { node in
      let update = { [weak node] in
        guard let node = node else { return }
        node[keyPath: kp] = transform(state1.wrappedValue, state2.wrappedValue, state3.wrappedValue, state4.wrappedValue)
      }
      state1.observe { _ in update() }
      state2.observe { _ in update() }
      state3.observe { _ in update() }
      state4.observe { _ in update() }
    }
    return s
  }

  /// Bind five GStates with a transformation function
  /// Usage: .bind(\.text, to: $a, $b, $c, $d, $e) { a, b, c, d, e in "\(a) - \(b) - \(c) - \(d) - \(e)" }
  func bind<V1, V2, V3, V4, V5, U>(
    _ kp: ReferenceWritableKeyPath<T, U>,
    to state1: GState<V1>,
    _ state2: GState<V2>,
    _ state3: GState<V3>,
    _ state4: GState<V4>,
    _ state5: GState<V5>,
    transform: @escaping (V1, V2, V3, V4, V5) -> U
  ) -> Self {
    var s = self
    s.ops.append { node in
      let update = { [weak node] in
        guard let node = node else { return }
        node[keyPath: kp] = transform(
          state1.wrappedValue, state2.wrappedValue, state3.wrappedValue,
          state4.wrappedValue, state5.wrappedValue
        )
      }
      state1.observe { _ in update() }
      state2.observe { _ in update() }
      state3.observe { _ in update() }
      state4.observe { _ in update() }
      state5.observe { _ in update() }
    }
    return s
  }

  /// Bind six GStates with a transformation function
  /// Usage: .bind(\.text, to: $a, $b, $c, $d, $e, $f) { a, b, c, d, e, f in ... }
  func bind<V1, V2, V3, V4, V5, V6, U>(
    _ kp: ReferenceWritableKeyPath<T, U>,
    to state1: GState<V1>,
    _ state2: GState<V2>,
    _ state3: GState<V3>,
    _ state4: GState<V4>,
    _ state5: GState<V5>,
    _ state6: GState<V6>,
    transform: @escaping (V1, V2, V3, V4, V5, V6) -> U
  ) -> Self {
    var s = self
    s.ops.append { node in
      let update = { [weak node] in
        guard let node = node else { return }
        node[keyPath: kp] = transform(
          state1.wrappedValue, state2.wrappedValue, state3.wrappedValue,
          state4.wrappedValue, state5.wrappedValue, state6.wrappedValue
        )
      }
      state1.observe { _ in update() }
      state2.observe { _ in update() }
      state3.observe { _ in update() }
      state4.observe { _ in update() }
      state5.observe { _ in update() }
      state6.observe { _ in update() }
    }
    return s
  }
}
