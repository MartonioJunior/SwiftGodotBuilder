import Foundation
import SwiftGodot

/// A type alias for ``GState`` to provide a more convenient API surface.
public typealias State = GState

// MARK: - ReactiveSource Protocol

/// A protocol that any reactive value source can conform to.
///
/// This protocol unifies `GState` and `ObservableProperty` under a common interface,
/// allowing reactive containers and bindings to work seamlessly with both @State and
/// @Observable properties.
///
/// ## Usage
///
/// Most users won't interact with this protocol directly - it's automatically
/// used when you pass `@State` variables or `@Observable` properties to reactive
/// containers like `If`, `Switch`, or binding methods.
///
/// ```swift
/// @State var count = 0
/// @ObservableState var viewModel = ViewModel()
///
/// // Both work seamlessly with ReactiveSource
/// If($viewModel.isVisible) { ... }  // ObservableProperty: ReactiveSource
/// Label$().text($count)  // GState: ReactiveSource
/// ```
public protocol ReactiveSource<Value> {
  associatedtype Value

  /// Observe changes to this reactive source.
  ///
  /// The handler is called immediately with the current value,
  /// and then again each time the value changes.
  ///
  /// - Parameter handler: A closure that receives the new value
  func observe(_ handler: @escaping (Value) -> Void)
}

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
@propertyWrapper
public final class GState<Value: Equatable> {
  private var value: Value
  private var listeners: [(Value) -> Void] = []

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
  public init(wrappedValue: Value) {
    value = wrappedValue
  }

  /// Registers a closure to be called whenever the state value changes.
  ///
  /// The handler is called immediately with the current value, and then
  /// again each time the value changes.
  ///
  /// - Parameter handler: A closure that receives the new value whenever it changes.
  func onChange(_ handler: @escaping (Value) -> Void) {
    listeners.append(handler)
    handler(value) // Call immediately with current value
  }

  /// Notifies all registered listeners of the current value.
  private func notifyListeners() {
    for listener in listeners {
      listener(value)
    }
  }
}

// MARK: - ReactiveSource Conformance

extension GState: ReactiveSource {
  /// Observe changes to this state.
  ///
  /// Simply delegates to `onChange` to maintain existing behavior.
  public func observe(_ handler: @escaping (Value) -> Void) {
    onChange(handler)
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
  func computed<U: Equatable>(_ transform: @escaping (Value) -> U) -> GState<U> {
    let derived = GState<U>(wrappedValue: transform(self.value))

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
    _ transform: @escaping (Value, T) -> U
  ) -> GState<U> {
    let derived = GState<U>(wrappedValue: transform(self.value, other.value))

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
    _ transform: @escaping (Value, T, U) -> V
  ) -> GState<V> {
    let derived = GState<V>(wrappedValue: transform(self.value, second.value, third.value))

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
    _ transform: @escaping (Value, T, U, V) -> W
  ) -> GState<W> {
    let derived = GState<W>(wrappedValue: transform(self.value, second.value, third.value, fourth.value))

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
}
