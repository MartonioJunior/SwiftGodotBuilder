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

    // Set up observation synchronously - no Task delay
    // This ensures we don't miss changes between initial read and observation setup
    setupObservation(keyPath: unsafeKeyPath, handler: unsafeHandler)
  }

  /// Internal helper to set up observation and call handler with current value
  private nonisolated func setupObservation<V>(keyPath: KeyPath<T, V>, handler: @escaping (V) -> Void) {
    nonisolated(unsafe) let unsafeHandler = handler
    nonisolated(unsafe) let unsafeKeyPath = keyPath

    // Call handler with current value
    unsafeHandler(self.object[keyPath: unsafeKeyPath])

    // Set up observation (one-shot, will re-register in onChange)
    withObservationTracking {
      _ = self.object[keyPath: unsafeKeyPath]
    } onChange: { [weak self] in
      guard let self else { return }

      ReactiveDebug.recordObservableChange(
        objectType: String(describing: T.self),
        keyPath: String(describing: unsafeKeyPath)
      )

      // Re-setup observation on next frame to avoid re-entrancy issues
      Engine.onNextFrame {
        self.setupObservation(keyPath: unsafeKeyPath, handler: unsafeHandler)
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

    // Set up observation synchronously
    setupAnyObservation(handler: unsafeHandler)
  }

  /// Internal helper to set up observation for any property change
  private nonisolated func setupAnyObservation(handler: @escaping (T) -> Void) {
    nonisolated(unsafe) let unsafeHandler = handler

    // Call handler with current object
    unsafeHandler(self.object)

    withObservationTracking {
      _ = self.object
    } onChange: { [weak self] in
      guard let self else { return }

      ReactiveDebug.recordObservableChange(
        objectType: String(describing: T.self),
        keyPath: "*any*"
      )

      Engine.onNextFrame {
        self.setupAnyObservation(handler: unsafeHandler)
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
      observableState.observe(sourceKeyPath) { [weak node] value in
        guard let node else { return }
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
      observableState.observe(sourceKeyPath) { [weak node] value in
        guard let node else { return }
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
      observableState.observe(sourceKeyPath) { [weak node] value in
        guard let node else { return }
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
      observableState.observeAny { [weak node] object in
        guard let node else { return }
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

// MARK: - Optional Type Protocol

/// Protocol to identify Optional types for dynamic member lookup chaining
public protocol OptionalType {
  associatedtype Wrapped
  var asOptional: Wrapped? { get }
}

extension Optional: OptionalType {
  public var asOptional: Wrapped? { self }
}

// MARK: - Mapped Observable Property

/// A wrapper that transforms an observable property's value.
///
/// This enables chaining through optional properties:
/// ```swift
/// // state.defense is ActorDefenseState?
/// // state.defense.health returns MappedObservableProperty<..., Int?>
/// Label$().text($state.defense.health) { "Health: \($0 ?? 0)" }
/// ```
@dynamicMemberLookup
public struct MappedObservableProperty<Root: AnyObject & Observable, Source, Value>: ReactiveSource {
  let observableState: ObservableState<Root>
  let sourceKeyPath: KeyPath<Root, Source>
  let transform: (Source) -> Value

  public func observe(_ handler: @escaping (Value) -> Void) {
    observableState.observe(sourceKeyPath) { source in
      handler(transform(source))
    }
  }

  /// Access the current transformed value
  public var value: Value {
    transform(observableState.object[keyPath: sourceKeyPath])
  }
}

// MARK: - Optional Chaining for ObservableProperty

public extension ObservableProperty where Value: OptionalType {
  /// Access properties of the wrapped optional type.
  ///
  /// When `Value` is optional (e.g., `ActorDefenseState?`), this allows
  /// accessing properties of the wrapped type, returning an optional result.
  ///
  /// ```swift
  /// // $state.defense is ObservableProperty<ActorState, ActorDefenseState?>
  /// // $state.defense.health is MappedObservableProperty<ActorState, ActorDefenseState?, Int?>
  /// Label$().text($state.defense.health) { "Health: \($0 ?? 0)" }
  /// ```
  subscript<U>(dynamicMember nestedKeyPath: KeyPath<Value.Wrapped, U>) -> MappedObservableProperty<Root, Value, U?> {
    MappedObservableProperty(
      observableState: observableState,
      sourceKeyPath: keyPath,
      transform: { $0.asOptional?[keyPath: nestedKeyPath] }
    )
  }
}

// MARK: - Chaining for MappedObservableProperty

public extension MappedObservableProperty where Value: OptionalType {
  /// Continue chaining through nested optionals
  subscript<U>(dynamicMember nestedKeyPath: KeyPath<Value.Wrapped, U>) -> MappedObservableProperty<Root, Source, U?> {
    MappedObservableProperty<Root, Source, U?>(
      observableState: observableState,
      sourceKeyPath: sourceKeyPath,
      transform: { self.transform($0).asOptional?[keyPath: nestedKeyPath] }
    )
  }
}

// MARK: - State Matching Helpers

public extension ObservableProperty where Value: Equatable {
  /// Returns a computed GState<Bool> that's true when the value equals the given value.
  ///
  /// Usage:
  /// ```swift
  /// .visible(router.scene.is(.paused))
  /// ```
  func `is`(_ value: Value) -> GState<Bool> {
    observableState.computed { $0[keyPath: keyPath] == value }
  }
}

public extension ObservableProperty where Value: Hashable {
  /// Returns a computed GState<Bool> that's true when the value is in the given set.
  ///
  /// Usage:
  /// ```swift
  /// .visible(router.scene.isIn(.inGame))
  /// ```
  func isIn(_ set: Set<Value>) -> GState<Bool> {
    observableState.computed { set.contains($0[keyPath: keyPath]) }
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

  /// Dynamic member lookup for ObservableProperty binding with transform.
  ///
  /// Usage: `.rotation(player.playerRotation) { Double($0) }`
  subscript<O: AnyObject & Observable, V, U>(
    dynamicMember kp: ReferenceWritableKeyPath<T, U>
  ) -> (ObservableProperty<O, V>, @escaping (V) -> U) -> Self {
    { observableProperty, transform in
      self.bind(kp, to: observableProperty.observableState, observableProperty.keyPath, transform: transform)
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

// MARK: - GNode Dynamic Member Lookup for MappedObservableProperty

public extension GNode {
  /// Dynamic member lookup for MappedObservableProperty binding with transform.
  ///
  /// Usage: `.text($state.defense.health) { "Health: \($0 ?? 0)" }`
  subscript<O: AnyObject & Observable, S, V, U>(
    dynamicMember kp: ReferenceWritableKeyPath<T, U>
  ) -> (MappedObservableProperty<O, S, V>, @escaping (V) -> U) -> Self {
    { mappedProperty, transform in
      var s = self
      s.ops.append { node in
        mappedProperty.observe { value in
          node[keyPath: kp] = transform(value)
        }
      }
      return s
    }
  }

  /// Direct binding for MappedObservableProperty when types match.
  subscript<O: AnyObject & Observable, S, V>(
    dynamicMember kp: ReferenceWritableKeyPath<T, V>
  ) -> (MappedObservableProperty<O, S, V>) -> Self {
    { mappedProperty in
      var s = self
      s.ops.append { node in
        mappedProperty.observe { value in
          node[keyPath: kp] = value
        }
      }
      return s
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
  func computed<U: Equatable>(
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (T) -> U
  ) -> GState<U> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)
    let derived = GState<U>(wrappedValue: transform(self.object), file: file, line: line)
    derived.markAsComputed()

    // Observe changes to the entire object
    observeAny { [derived] object in
      derived.wrappedValue = transform(object)
    }

    return derived
  }
}

// MARK: - SceneRouter Convenience Methods

/// Convenience methods for `ObservableState` wrapping a `SceneRouterProtocol`.
///
/// These enable cleaner syntax without `.wrappedValue`:
///
/// ## Usage
/// ```swift
/// @ObservableState var router = SceneRouter(initial: GameState.splash)
///
/// // Navigation (instead of router.wrappedValue.navigate)
/// router.navigate(to: .playing, transition: .fade())
/// router.navigate(to: .playing, transition: .fade()) {
///   state.reset()
/// }
///
/// // Scene access (instead of router.wrappedValue.scene)
/// router.scene = .playing
/// if router.scene == .paused { ... }
/// guard router.scene.isActive else { return }
/// ```
public extension ObservableState where T: SceneRouterProtocol {
  /// The current scene. Read/write access without `.wrappedValue`.
  var scene: T.Scene {
    get { object.scene }
    set { object.scene = newValue }
  }

  /// The transition state for visual effects.
  var transitionState: TransitionState {
    object.transitionState
  }

  /// Navigate to a new scene with an optional transition effect.
  ///
  /// - Parameters:
  ///   - scene: The destination scene
  ///   - transition: The transition style to use (default: `.fade()`)
  ///   - onComplete: Optional callback when the transition completes
  func navigate(
    to scene: T.Scene,
    transition: TransitionStyle = .fade(),
    onComplete: (() -> Void)? = nil
  ) {
    object.navigate(to: scene, transition: transition, onComplete: onComplete)
  }

  /// Navigate to a new scene with a transition, executing additional work at the midpoint.
  ///
  /// - Parameters:
  ///   - scene: The destination scene
  ///   - transition: The transition style to use
  ///   - atMidpoint: Additional work to perform at midpoint (after scene change)
  ///   - onComplete: Optional callback when the transition completes
  func navigate(
    to scene: T.Scene,
    transition: TransitionStyle,
    atMidpoint: @escaping () -> Void,
    onComplete: (() -> Void)? = nil
  ) {
    object.navigate(to: scene, transition: transition, atMidpoint: atMidpoint, onComplete: onComplete)
  }
}
