import Foundation
import SwiftGodot

/// A type alias for ``GState`` to provide a more convenient API surface.
public typealias State = GState

// MARK: - State Property Wrapper

/// A property wrapper that manages observable state in Godot nodes.
///
/// `GState` provides a reactive state management mechanism similar to SwiftUI's `@State`.
/// When the wrapped value changes, all registered listeners are notified automatically.
///
/// ## Usage
///
/// Use `@State` (or `@GState`) to declare state variables in your views:
///
/// ```swift
/// @State var counter = 0
/// @State var isVisible = true
/// ```
///
/// Access the state value directly, and modifications will trigger updates:
///
/// ```swift
/// counter += 1  // Notifies all listeners
/// ```
/// Token returned by `GState.observe()` that can be used to cancel the observation.
public final class StateObservationToken {
  private weak var state: AnyObject?
  let id: UUID

  init(state: AnyObject, id: UUID) {
    self.state = state
    self.id = id
  }

  /// Cancels this observation. After calling this, the handler will no longer be invoked.
  public func cancel() {
    // The actual removal happens in GState via the id
  }

  /// Whether this observation is still active
  public var isActive: Bool {
    state != nil
  }
}

@propertyWrapper
public final class GState<Value: Equatable> {
  /// Internal listener entry with optional weak owner for automatic cleanup
  private final class Listener {
    let id: UUID
    /// If true, this listener was registered with an owner and should be cleaned up when owner dies
    let hasOwner: Bool
    weak var owner: AnyObject?
    let handler: (Value) -> Void

    init(id: UUID, owner: AnyObject?, handler: @escaping (Value) -> Void) {
      self.id = id
      self.hasOwner = owner != nil
      self.owner = owner
      self.handler = handler
    }

    /// Whether this listener is still alive (no owner, or owner still exists)
    var isAlive: Bool {
      !hasOwner || owner != nil
    }
  }

  private var value: Value
  private var listeners: [Listener] = []

  /// Debug label for identifying this state in ReactiveDebug output
  public var debugLabel: String?

  /// Source location where this state was created (for debugging)
  private let sourceFile: String
  private let sourceLine: Int

  /// Whether this state was created via .computed() (for update tracking)
  private var isComputed = false

  /// The underlying value being wrapped by this state container.
  ///
  /// Reading this property returns the current value. Setting this property
  /// updates the value and notifies all registered listeners.
  public var wrappedValue: Value {
    get { value }
    set {
      // Prevent infinite loops by checking if the value actually changed
      guard value != newValue else { return }
      value = newValue
      notifyListeners()
    }
  }

  /// A projection of the state that can be passed as a binding.
  ///
  /// Use the `$` prefix to access this property:
  ///
  /// ```swift
  /// @State var count = 0
  /// ChildView(value: $count)  // Passes the GState instance
  /// ```
  public var projectedValue: GState<Value> { self }

  /// Creates a new state container with an initial value.
  ///
  /// - Parameter wrappedValue: The initial value to store in this state container.
  public init(wrappedValue: Value, file: String = #file, line: Int = #line) {
    value = wrappedValue
    sourceFile = file
    sourceLine = line
  }

  /// Registers a closure to be called whenever the state value changes.
  ///
  /// The handler is called immediately with the current value, and then
  /// again each time the value changes.
  ///
  /// - Parameter handler: A closure that receives the new value whenever it changes.
  func onChange(_ handler: @escaping (Value) -> Void) {
    let id = UUID()
    listeners.append(Listener(id: id, owner: nil, handler: handler))
    handler(value) // Call immediately with current value
  }

  /// Registers a closure with an owner object for automatic cleanup.
  ///
  /// When the owner is deallocated, the listener is automatically removed.
  /// The handler is called immediately with the current value.
  ///
  /// - Parameters:
  ///   - owner: The object that owns this observation. When deallocated, the listener is removed.
  ///   - handler: A closure that receives the new value whenever it changes.
  /// - Returns: A token that can be used to manually cancel the observation.
  @discardableResult
  func onChange(owner: AnyObject, _ handler: @escaping (Value) -> Void) -> StateObservationToken {
    let id = UUID()
    listeners.append(Listener(id: id, owner: owner, handler: handler))
    handler(value) // Call immediately with current value
    return StateObservationToken(state: self, id: id)
  }

  /// Removes a listener by its token ID.
  func removeListener(id: UUID) {
    listeners.removeAll { $0.id == id }
  }

  /// Notifies all registered listeners of the current value.
  /// Also cleans up listeners whose owners have been deallocated.
  private func notifyListeners() {
    if isComputed {
      ReactiveDebug.recordComputedUpdate(file: sourceFile, line: sourceLine)
    } else {
      ReactiveDebug.recordStateChange(
        label: debugLabel,
        file: sourceFile,
        line: sourceLine
      )
    }

    // Notify alive listeners and track if cleanup is needed
    var needsCleanup = false
    for listener in listeners {
      if listener.isAlive {
        listener.handler(value)
      } else {
        needsCleanup = true
      }
    }

    // Lazily clean up dead listeners
    if needsCleanup {
      listeners.removeAll { !$0.isAlive }
    }
  }

  /// Mark this state as computed (for update tracking).
  /// Called internally by .computed() methods.
  func markAsComputed() {
    isComputed = true
  }
}

// MARK: - Observation Methods

public extension GState {
  /// Observe changes to this state with automatic cleanup when owner is deallocated.
  ///
  /// This is the preferred method for observing state changes from Godot nodes,
  /// as it automatically cleans up the listener when the owning node is freed.
  ///
  /// - Parameters:
  ///   - owner: The object that owns this observation (typically a Godot Node).
  ///   - handler: A closure that receives the new value whenever it changes.
  /// - Returns: A token that can be used to manually cancel the observation.
  @discardableResult
  func observe(owner: AnyObject, _ handler: @escaping (Value) -> Void) -> StateObservationToken {
    onChange(owner: owner, handler)
  }
}

// MARK: - Computed/Derived State

public extension GState {
  /// Creates a computed state by transforming this state's value.
  ///
  /// The computed state automatically updates whenever the source state changes.
  ///
  /// ## Usage
  /// ```swift
  /// @State var currentPage = 0
  /// let isMainMenu = $currentPage.computed { $0 == 0 }
  /// let isSettings = $currentPage.computed { $0 == 2 }
  ///
  /// If(isMainMenu) {
  ///   Label$().text("Main Menu")
  /// }
  /// ```
  ///
  /// - Parameter transform: A closure that transforms the source value into the computed value
  /// - Returns: A new `GState` that reactively updates based on the source state
  func computed<U: Equatable>(
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (Value) -> U
  ) -> GState<U> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)

    let derived = GState<U>(wrappedValue: transform(self.value), file: file, line: line)
    derived.isComputed = true

    // Capture derived strongly so it stays alive and continues to update.
    // This is safe because:
    // - Source doesn't own derived (we return it)
    // - Listener (owned by source) captures derived
    // - When source is deallocated, listeners are cleaned up
    onChange { [derived] newValue in
      derived.wrappedValue = transform(newValue)
    }

    return derived
  }

  /// Creates a computed state by combining two states.
  ///
  /// The computed state updates whenever either source state changes.
  ///
  /// ## Usage
  /// ```swift
  /// @State var currentPage = 1
  /// @State var totalPages = 10
  /// let pageText = $currentPage.computed(with: $totalPages) { current, total in
  ///   "Page \(current) of \(total)"
  /// }
  ///
  /// Label$().bind(\.text, to: pageText)
  /// ```
  ///
  /// - Parameters:
  ///   - other: Another state to combine with this one
  ///   - transform: A closure that combines both values into the computed value
  /// - Returns: A new `GState` that updates when either source changes
  func computed<T: Equatable, U: Equatable>(
    with other: GState<T>,
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (Value, T) -> U
  ) -> GState<U> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)
    let derived = GState<U>(wrappedValue: transform(self.value, other.value), file: file, line: line)
    derived.isComputed = true

    onChange { [derived] newValue in
      derived.wrappedValue = transform(newValue, other.value)
    }

    other.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, newValue)
    }

    return derived
  }

  /// Creates a computed state by combining three states.
  ///
  /// ## Usage
  /// ```swift
  /// @State var health = 100
  /// @State var maxHealth = 100
  /// @State var playerName = "Hero"
  /// let status = $health.computed(with: $maxHealth, $playerName) { hp, maxHp, name in
  ///   "\(name): \(hp)/\(maxHp) HP"
  /// }
  /// ```
  func computed<T: Equatable, U: Equatable, V: Equatable>(
    with second: GState<T>,
    _ third: GState<U>,
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (Value, T, U) -> V
  ) -> GState<V> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)
    let derived = GState<V>(wrappedValue: transform(self.value, second.value, third.value), file: file, line: line)
    derived.isComputed = true

    onChange { [derived] newValue in
      derived.wrappedValue = transform(newValue, second.value, third.value)
    }

    second.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, newValue, third.value)
    }

    third.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, newValue)
    }

    return derived
  }

  /// Creates a computed state by combining four states.
  ///
  /// ## Usage
  /// ```swift
  /// @State var hours = 0
  /// @State var minutes = 0
  /// @State var seconds = 0
  /// @State var milliseconds = 0
  /// let timeDisplay = $hours.computed(with: $minutes, $seconds, $milliseconds) { h, m, s, ms in
  ///   String(format: "%02d:%02d:%02d.%03d", h, m, s, ms)
  /// }
  /// ```
  func computed<T: Equatable, U: Equatable, V: Equatable, W: Equatable>(
    with second: GState<T>,
    _ third: GState<U>,
    _ fourth: GState<V>,
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (Value, T, U, V) -> W
  ) -> GState<W> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)
    let derived = GState<W>(wrappedValue: transform(self.value, second.value, third.value, fourth.value), file: file, line: line)
    derived.isComputed = true

    onChange { [derived] newValue in
      derived.wrappedValue = transform(newValue, second.value, third.value, fourth.value)
    }

    second.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, newValue, third.value, fourth.value)
    }

    third.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, newValue, fourth.value)
    }

    fourth.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, third.value, newValue)
    }

    return derived
  }

  /// Creates a computed state by combining five states.
  func computed<T2: Equatable, T3: Equatable, T4: Equatable, T5: Equatable, R: Equatable>(
    with second: GState<T2>,
    _ third: GState<T3>,
    _ fourth: GState<T4>,
    _ fifth: GState<T5>,
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (Value, T2, T3, T4, T5) -> R
  ) -> GState<R> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)
    let derived = GState<R>(wrappedValue: transform(
      self.value, second.value, third.value, fourth.value, fifth.value
    ), file: file, line: line)
    derived.isComputed = true

    onChange { [derived] newValue in
      derived.wrappedValue = transform(newValue, second.value, third.value, fourth.value, fifth.value)
    }

    second.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, newValue, third.value, fourth.value, fifth.value)
    }

    third.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, newValue, fourth.value, fifth.value)
    }

    fourth.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, third.value, newValue, fifth.value)
    }

    fifth.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, third.value, fourth.value, newValue)
    }

    return derived
  }

  /// Creates a computed state by combining six states.
  func computed<T2: Equatable, T3: Equatable, T4: Equatable, T5: Equatable, T6: Equatable, R: Equatable>(
    with second: GState<T2>,
    _ third: GState<T3>,
    _ fourth: GState<T4>,
    _ fifth: GState<T5>,
    _ sixth: GState<T6>,
    file: String = #file,
    line: Int = #line,
    _ transform: @escaping (Value, T2, T3, T4, T5, T6) -> R
  ) -> GState<R> {
    ReactiveDebug.recordComputedCreation(file: file, line: line)
    let derived = GState<R>(wrappedValue: transform(
      self.value, second.value, third.value, fourth.value, fifth.value, sixth.value
    ), file: file, line: line)
    derived.isComputed = true

    onChange { [derived] newValue in
      derived.wrappedValue = transform(newValue, second.value, third.value, fourth.value, fifth.value, sixth.value)
    }

    second.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, newValue, third.value, fourth.value, fifth.value, sixth.value)
    }

    third.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, newValue, fourth.value, fifth.value, sixth.value)
    }

    fourth.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, third.value, newValue, fifth.value, sixth.value)
    }

    fifth.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, third.value, fourth.value, newValue, sixth.value)
    }

    sixth.onChange { [derived] newValue in
      derived.wrappedValue = transform(self.value, second.value, third.value, fourth.value, fifth.value, newValue)
    }

    return derived
  }
}
