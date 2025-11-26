import Foundation
import Observation
import SwiftGodot

// MARK: - ObservableState Wrapper

/// A state container that tracks changes to `@Observable` classes.
///
/// `ObservableState` integrates Swift's `@Observable` macro with the reactive system,
/// allowing you to use observable classes as state in your Godot views.
/// Observable properties work natively with reactive containers (If, Switch, ForEach)
/// and bindings via the `ReactiveSource` protocol.
///
/// ## Usage
///
/// Define an observable class:
///
/// ```swift
/// @Observable
/// class GameViewModel {
///   var score: Int = 0
///   var playerName: String = "Player"
///   var isGameOver: Bool = false
/// }
/// ```
///
/// Use it in a GView:
///
/// ```swift
/// struct GameView: GView {
///   let state = ObservableState(GameViewModel())
///
///   var body: some GView {
///     VBoxContainer$ {
///       Label$()
///         .bind(\.text, to: state, \.playerName)
///
///       Label$()
///         .bind(\.text, to: state, \.score) { "Score: \($0)" }
///     }
///   }
/// }
/// ```
@propertyWrapper
@dynamicMemberLookup
public final class ObservableState<T: AnyObject & Observable>: @unchecked Sendable {
  /// The underlying observable object
  public nonisolated(unsafe) let object: T

  /// The wrapped value - provides direct access to the observable object.
  ///
  /// Use this to access the object without the `.object` suffix:
  /// ```swift
  /// @ObservableState var state = GameViewModel()
  /// // Access via wrappedValue
  /// state.score += 10
  /// ```
  public var wrappedValue: T {
    object
  }

  /// The projected value - returns self for use with bindings.
  ///
  /// Use the `$` prefix to access the ObservableState wrapper:
  /// ```swift
  /// @ObservableState var state = GameViewModel()
  /// // Access the wrapper
  /// Label$().text($state.score)
  /// ```
  public var projectedValue: ObservableState<T> {
    self
  }

  /// Creates a new state container wrapping an observable object.
  ///
  /// - Parameter wrappedValue: The observable object to wrap
  public init(wrappedValue: T) {
    self.object = wrappedValue
  }

  /// Creates a new state container wrapping an observable object.
  ///
  /// This initializer is provided for backwards compatibility.
  ///
  /// - Parameter object: The observable object to wrap
  public convenience init(_ object: T) {
    self.init(wrappedValue: object)
  }

  /// Observes a specific key path on the observable object and calls a handler when it changes.
  ///
  /// The handler is called immediately with the current value, and then again whenever the value changes.
  ///
  /// - Parameters:
  ///   - keyPath: The key path to observe
  ///   - handler: A closure that receives the new value whenever it changes
  public nonisolated func observe<V>(_ keyPath: KeyPath<T, V>, handler: @escaping (V) -> Void) {
    nonisolated(unsafe) let unsafeHandler = handler
    nonisolated(unsafe) let unsafeKeyPath = keyPath

    Task { @MainActor [weak self] in
      guard let self = self else { return }

      // Call immediately with current value
      unsafeHandler(self.object[keyPath: unsafeKeyPath])

      // Set up observation for future changes
      await self.observeChanges(keyPath: unsafeKeyPath, handler: unsafeHandler)
    }
  }

  /// Internal helper to set up observation tracking
  @MainActor
  private func observeChanges<V>(keyPath: KeyPath<T, V>, handler: @escaping (V) -> Void) async {
    // Safe: handler and keyPath are only used on the main thread
    nonisolated(unsafe) let unsafeHandler = handler
    nonisolated(unsafe) let unsafeKeyPath = keyPath

    withObservationTracking {
      // Access the property to register it with the observation system
      _ = object[keyPath: unsafeKeyPath]
    } onChange: { [weak self] in
      // Safe: ObservableState is @unchecked Sendable and everything runs on main thread
      // Warning about T.Type capture is benign since all observation runs on main thread
      Task { @MainActor in
        guard let self else { return }

        // Call handler with new value
        unsafeHandler(self.object[keyPath: unsafeKeyPath])

        // Re-establish observation (observation is one-shot)
        await self.observeChanges(keyPath: unsafeKeyPath, handler: unsafeHandler)
      }
    }
  }

  /// Observes the entire observable object and calls a handler when any property changes.
  ///
  /// This is useful when you want to react to any change in the object without tracking specific properties.
  ///
  /// - Parameter handler: A closure that receives the object whenever any property changes
  public nonisolated func observeAny(handler: @escaping (T) -> Void) {
    nonisolated(unsafe) let unsafeHandler = handler

    Task { @MainActor [weak self] in
      guard let self = self else { return }

      // Call immediately with current object
      unsafeHandler(self.object)

      // Set up observation for future changes
      await self.observeAnyChanges(handler: unsafeHandler)
    }
  }

  /// Internal helper to set up observation tracking for any changes
  @MainActor
  private func observeAnyChanges(handler: @escaping (T) -> Void) async {
    // Safe: handler is only used on the main thread
    nonisolated(unsafe) let unsafeHandler = handler

    withObservationTracking {
      // Access the object to register observation
      _ = object
    } onChange: { [weak self] in
      // Safe: ObservableState is @unchecked Sendable and everything runs on main thread
      // Warning about T.Type capture is benign since all observation runs on main thread
      Task { @MainActor in
        guard let self else { return }

        // Call handler with object
        unsafeHandler(self.object)

        // Re-establish observation (observation is one-shot)
        await self.observeAnyChanges(handler: unsafeHandler)
      }
    }
  }
}

// MARK: - GNode Binding Extensions for ObservableState

public extension GNode {
  /// Bind an observable property to a node property
  ///
  /// Usage:
  /// ```swift
  /// let state = ObservableState(GameViewModel())
  /// Label$().bind(\.text, to: state, \.playerName)
  /// ```
  func bind<O: AnyObject & Observable, V>(
    _ kp: ReferenceWritableKeyPath<T, V>,
    to observableState: ObservableState<O>,
    _ sourceKeyPath: KeyPath<O, V>
  ) -> Self {
    var s = self
    s.ops.append { [observableState] node in
      observableState.observe(sourceKeyPath) { value in
        node[keyPath: kp] = value
      }
    }
    return s
  }

  /// Bind an observable property to a node property with a transformation
  ///
  /// Usage:
  /// ```swift
  /// let state = ObservableState(GameViewModel())
  /// Label$().bind(\.text, to: state, \.score) { "Score: \($0)" }
  /// ```
  func bind<O: AnyObject & Observable, V, U>(
    _ kp: ReferenceWritableKeyPath<T, U>,
    to observableState: ObservableState<O>,
    _ sourceKeyPath: KeyPath<O, V>,
    transform: @escaping (V) -> U
  ) -> Self {
    var s = self
    s.ops.append { [observableState] node in
      observableState.observe(sourceKeyPath) { value in
        node[keyPath: kp] = transform(value)
      }
    }
    return s
  }

  /// Watch an observable property and execute custom logic when it changes
  ///
  /// Usage:
  /// ```swift
  /// let state = ObservableState(GameViewModel())
  /// CharacterBody2D$()
  ///   .watch(state, \.isGameOver) { node, isOver in
  ///     if isOver {
  ///       node.position = Vector2(x: 0, y: 0)
  ///     }
  ///   }
  /// ```
  func watch<O: AnyObject & Observable, V>(
    _ observableState: ObservableState<O>,
    _ sourceKeyPath: KeyPath<O, V>,
    _ handler: @escaping (T, V) -> Void
  ) -> Self {
    var s = self
    s.ops.append { [observableState] node in
      observableState.observe(sourceKeyPath) { value in
        handler(node, value)
      }
    }
    return s
  }

  /// Watch the entire observable object and execute custom logic when any property changes
  ///
  /// Usage:
  /// ```swift
  /// let state = ObservableState(GameViewModel())
  /// Node2D$()
  ///   .watchAny(state) { node, vm in
  ///     print("ViewModel changed: \(vm.score)")
  ///   }
  /// ```
  func watchAny<O: AnyObject & Observable>(
    _ observableState: ObservableState<O>,
    _ handler: @escaping (T, O) -> Void
  ) -> Self {
    var s = self
    s.ops.append { [observableState] node in
      observableState.observeAny { object in
        handler(node, object)
      }
    }
    return s
  }
}

// MARK: - Observable Property Wrapper

/// A wrapper that combines an ObservableState with a specific property keypath.
///
/// This allows for concise binding syntax like `.text($state.score)` instead of
/// `.bind(\.text, to: state, \.score)`.
@dynamicMemberLookup
public struct ObservableProperty<Root: AnyObject & Observable, Value> {
  let observableState: ObservableState<Root>
  let keyPath: KeyPath<Root, Value>

  /// Access nested properties via dynamic member lookup
  public subscript<U>(dynamicMember nestedKeyPath: KeyPath<Value, U>) -> ObservableProperty<Root, U> {
    ObservableProperty<Root, U>(
      observableState: observableState,
      keyPath: keyPath.appending(path: nestedKeyPath)
    )
  }

  /// Access the actual value for use outside of bindings
  public var value: Value {
    observableState.object[keyPath: keyPath]
  }
}

// MARK: - ReactiveSource Conformance

extension ObservableProperty: ReactiveSource {
  /// Observe changes to this observable property.
  ///
  /// Delegates to the underlying ObservableState's observe mechanism.
  public func observe(_ handler: @escaping (Value) -> Void) {
    observableState.observe(keyPath, handler: handler)
  }
}

// MARK: - ObservableState Dynamic Member Lookup

public extension ObservableState {
  /// Access properties via dynamic member lookup to create ObservableProperty wrappers.
  ///
  /// Usage:
  /// ```swift
  /// let state = ObservableState(GameViewModel())
  /// Label$().text(state.score)  // Returns ObservableProperty for binding
  /// Label$().position(state.playerPosition)
  /// ```
  subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> ObservableProperty<T, V> {
    ObservableProperty(observableState: self, keyPath: keyPath)
  }
}

// MARK: - GNode Dynamic Member Lookup for ObservableProperty

public extension GNode {
  /// Dynamic member lookup for ObservableProperty binding.
  ///
  /// Usage: `.text($state.score)` or `.position($state.playerPosition)`
  subscript<O: AnyObject & Observable, V>(
    dynamicMember kp: ReferenceWritableKeyPath<T, V>
  ) -> (ObservableProperty<O, V>) -> Self {
    { observableProperty in
      self.bind(kp, to: observableProperty.observableState, observableProperty.keyPath)
    }
  }

  /// Dynamic member lookup for ObservableProperty with StringName conversion.
  subscript<O: AnyObject & Observable>(
    dynamicMember kp: ReferenceWritableKeyPath<T, StringName>
  ) -> (ObservableProperty<O, String>) -> Self {
    { observableProperty in
      self.bind(kp, to: observableProperty.observableState, observableProperty.keyPath) { StringName($0) }
    }
  }
}

// MARK: - Legacy Dynamic Member Lookup (for backwards compatibility)

public extension GNode {
  /// Dynamic member lookup for ObservableState binding (legacy two-parameter syntax)
  ///
  /// Usage: `.position(state, \.playerPosition)`
  ///
  /// Note: Prefer the new syntax `.position($state.playerPosition)` instead.
  subscript<O: AnyObject & Observable, V>(
    dynamicMember kp: ReferenceWritableKeyPath<T, V>
  ) -> (ObservableState<O>, KeyPath<O, V>) -> Self {
    { observableState, sourceKeyPath in
      self.bind(kp, to: observableState, sourceKeyPath)
    }
  }
}

// MARK: - Computed/Derived State for ObservableState

public extension ObservableState {
  /// Creates a computed state by transforming the observable object.
  ///
  /// The computed state automatically updates whenever the observable object changes.
  ///
  /// ## Usage
  /// ```swift
  /// @ObservableState var progress = GameProgress()
  ///
  /// var isUnlocked: GState<Bool> {
  ///   progress.computed { progressValue in
  ///     progressValue.isLevelUnlocked(levelId, levels: levels)
  ///   }
  /// }
  ///
  /// Button$().disabled(isUnlocked)
  /// ```
  ///
  /// - Parameter transform: A closure that transforms the observable object into the computed value
  /// - Returns: A new `GState` that reactively updates based on the observable object
  func computed<U: Equatable>(_ transform: @escaping (T) -> U) -> GState<U> {
    let derived = GState<U>(wrappedValue: transform(self.object))

    // Observe changes to the entire object
    observeAny { [derived] object in
      derived.wrappedValue = transform(object)
    }

    return derived
  }
}
