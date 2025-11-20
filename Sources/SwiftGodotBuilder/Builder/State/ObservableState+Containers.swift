import Observation
import SwiftGodot

// MARK: - If Container with ObservableState

public extension If {
  /// Creates a conditional container that observes a boolean property from an @Observable object
  ///
  /// ## Usage
  /// ```swift
  /// @Observable
  /// class GameViewModel {
  ///   var isGameOver: Bool = false
  /// }
  ///
  /// let state = ObservableState(GameViewModel())
  ///
  /// If(state, \.isGameOver) {
  ///   GameOverScreen$()
  /// }
  /// ```
  @MainActor
  init<O: AnyObject & Observable>(
    _ observableState: ObservableState<O>,
    _ keyPath: KeyPath<O, Bool>,
    @NodeBuilder content: @escaping () -> [any GView]
  ) {
    // Create a GState that mirrors the observable property
    let state = GState(wrappedValue: observableState.object[keyPath: keyPath])

    // Keep the state in sync with the observable
    observableState.observe(keyPath) { newValue in
      state.wrappedValue = newValue
    }

    self.init(state, content: content)
  }
}

// MARK: - ForEach Container with ObservableState

public extension ForEach {
  /// Creates a ForEach container that observes an array property from an @Observable object
  ///
  /// ## Usage
  /// ```swift
  /// @Observable
  /// class GameViewModel {
  ///   var items: [Item] = []
  /// }
  ///
  /// let state = ObservableState(GameViewModel())
  ///
  /// VBoxContainer$ {
  ///   ForEach(state, \.items, id: \.id) { $item in
  ///     Label$().text(item.name)
  ///   }
  /// }
  /// ```
  @MainActor
  init<O: AnyObject & Observable>(
    _ observableState: ObservableState<O>,
    _ keyPath: KeyPath<O, [Element]>,
    id: KeyPath<Element, ID>,
    mode: Mode = .standard,
    content: @escaping (GState<Element>) -> any GView
  ) {
    // Create a GState that mirrors the observable property
    let state = GState(wrappedValue: observableState.object[keyPath: keyPath])

    // Keep the state in sync with the observable
    observableState.observe(keyPath) { newValue in
      state.wrappedValue = newValue
    }

    self.init(state, id: id, mode: mode, content: content)
  }
}

public extension ForEach where Element: Identifiable, ID == Element.ID {
  /// Creates a ForEach for Identifiable items from an @Observable object
  ///
  /// ## Usage
  /// ```swift
  /// @Observable
  /// class GameViewModel {
  ///   var players: [Player] = []  // Player conforms to Identifiable
  /// }
  ///
  /// let state = ObservableState(GameViewModel())
  ///
  /// VBoxContainer$ {
  ///   ForEach(state, \.players) { $player in
  ///     Label$().text(player.name)
  ///   }
  /// }
  /// ```
  @MainActor
  init<O: AnyObject & Observable>(
    _ observableState: ObservableState<O>,
    _ keyPath: KeyPath<O, [Element]>,
    mode: Mode = .standard,
    content: @escaping (GState<Element>) -> any GView
  ) {
    // Create a GState that mirrors the observable property
    let state = GState(wrappedValue: observableState.object[keyPath: keyPath])

    // Keep the state in sync with the observable
    observableState.observe(keyPath) { newValue in
      state.wrappedValue = newValue
    }

    self.init(state, mode: mode, content: content)
  }
}
