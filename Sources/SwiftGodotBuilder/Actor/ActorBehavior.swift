import Foundation
import SwiftGodot

// MARK: - Actor Behavior Protocol

/// Protocol for behaviors that control actor actions each frame
public protocol ActorBehavior: Sendable {
  /// Called each physics frame to update the behavior
  mutating func process(actor: ActorState, delta: Double)

  /// Called when entering this behavior's state
  mutating func enter(actor: ActorState)

  /// Called when exiting this behavior's state
  mutating func exit(actor: ActorState)
}

// Default implementations
public extension ActorBehavior {
  func enter(actor: ActorState) {}
  func exit(actor: ActorState) {}
}

// MARK: - Behavior Output

/// Output from a behavior that affects actor state
public struct BehaviorOutput: Sendable {
  public var inputDirection: Float?
  public var jumpRequested: Bool?
  public var attackRequested: Bool?
  public var facingOverride: Facing?

  public init(
    inputDirection: Float? = nil,
    jumpRequested: Bool? = nil,
    attackRequested: Bool? = nil,
    facingOverride: Facing? = nil
  ) {
    self.inputDirection = inputDirection
    self.jumpRequested = jumpRequested
    self.attackRequested = attackRequested
    self.facingOverride = facingOverride
  }

  public static let none = BehaviorOutput()
}

// MARK: - Behavior Machine

/// State machine for actor behaviors
public class BehaviorMachine<S: Hashable & Sendable>: @unchecked Sendable {
  public private(set) var currentState: S
  private var states: [S: BehaviorState<S>]
  private var hasEnteredInitialState = false

  public init(initial: S, @BehaviorMachineBuilder<S> _ builder: () -> [BehaviorState<S>]) {
    currentState = initial
    let stateList = builder()
    states = Dictionary(uniqueKeysWithValues: stateList.map { ($0.id, $0) })
    validate(initial: initial)
  }

  private func validate(initial: S) {
    // Check initial state exists
    if states[initial] == nil {
      GD.pushWarning("BehaviorMachine: initial state '\(initial)' has no During block")
    }

    // Check all transition targets exist
    for (stateId, state) in states {
      for transition in state.transitions {
        if states[transition.target] == nil {
          GD.pushWarning("BehaviorMachine: state '\(stateId)' transitions to '\(transition.target)' which has no During block")
        }
      }
    }
  }

  /// Process the current state's behaviors and check transitions
  public func process(actor: ActorState, delta: Double) {
    // Enter initial state on first process
    if !hasEnteredInitialState {
      hasEnteredInitialState = true
      states[currentState]?.enter(actor: actor)
    }

    // Check transitions first
    if let state = states[currentState] {
      for transition in state.transitions {
        if transition.condition(actor) {
          transitionTo(transition.target, actor: actor)
          break
        }
      }
    }

    // Process current state's behaviors
    states[currentState]?.process(actor: actor, delta: delta)
  }

  /// Force transition to a specific state
  public func transitionTo(_ newState: S, actor: ActorState) {
    guard newState != currentState else { return }

    states[currentState]?.exit(actor: actor)
    currentState = newState
    states[currentState]?.enter(actor: actor)
  }
}

// MARK: - Behavior State

/// A single state in the behavior machine containing behaviors and transitions
public class BehaviorState<S: Hashable & Sendable>: @unchecked Sendable {
  public let id: S
  var behaviors: [any ActorBehavior]
  var transitions: [BehaviorTransition<S>]

  public init(_ id: S, @BehaviorBuilder _ builder: () -> [any ActorBehavior]) {
    self.id = id
    behaviors = builder()
    transitions = []
  }

  /// Add a transition to another state
  public func transition(
    to target: S,
    when condition: @escaping @Sendable (ActorState) -> Bool
  ) -> BehaviorState<S> {
    transitions.append(BehaviorTransition(target: target, condition: condition))
    return self
  }

  func process(actor: ActorState, delta: Double) {
    for i in behaviors.indices {
      behaviors[i].process(actor: actor, delta: delta)
    }
  }

  func enter(actor: ActorState) {
    for i in behaviors.indices {
      behaviors[i].enter(actor: actor)
    }
  }

  func exit(actor: ActorState) {
    for i in behaviors.indices {
      behaviors[i].exit(actor: actor)
    }
  }
}

// MARK: - Behavior Transition

/// A transition from one state to another
public struct BehaviorTransition<S: Hashable & Sendable>: Sendable {
  public let target: S
  public let condition: @Sendable (ActorState) -> Bool

  public init(target: S, condition: @escaping @Sendable (ActorState) -> Bool) {
    self.target = target
    self.condition = condition
  }
}

// MARK: - Type-Erased Behavior Machine

/// Type-erased wrapper for BehaviorMachine to allow storage without knowing state type
public class AnyBehaviorMachine: @unchecked Sendable {
  private let _process: (ActorState, Double) -> Void

  public init<S: Hashable & Sendable>(_ machine: BehaviorMachine<S>) {
    _process = { actor, delta in
      machine.process(actor: actor, delta: delta)
    }
  }

  public func process(actor: ActorState, delta: Double) {
    _process(actor, delta)
  }
}

// MARK: - Convenience Function

/// Convenience function to create a behavior state
public func During<S: Hashable & Sendable>(
  _ id: S,
  @BehaviorBuilder _ builder: () -> [any ActorBehavior]
) -> BehaviorState<S> {
  BehaviorState(id, builder)
}

// MARK: - Result Builders

/// Result builder for constructing behavior machine states
@resultBuilder
public struct BehaviorMachineBuilder<S: Hashable & Sendable> {
  public static func buildBlock(_ states: BehaviorState<S>...) -> [BehaviorState<S>] {
    states
  }

  public static func buildArray(_ components: [[BehaviorState<S>]]) -> [BehaviorState<S>] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [BehaviorState<S>]?) -> [BehaviorState<S>] {
    component ?? []
  }

  public static func buildEither(first component: [BehaviorState<S>]) -> [BehaviorState<S>] {
    component
  }

  public static func buildEither(second component: [BehaviorState<S>]) -> [BehaviorState<S>] {
    component
  }
}

/// Result builder for constructing behaviors within a state
@resultBuilder
public struct BehaviorBuilder {
  public static func buildBlock(_ components: [any ActorBehavior]...) -> [any ActorBehavior] {
    components.flatMap { $0 }
  }

  public static func buildArray(_ components: [[any ActorBehavior]]) -> [any ActorBehavior] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [any ActorBehavior]?) -> [any ActorBehavior] {
    component ?? []
  }

  public static func buildEither(first component: [any ActorBehavior]) -> [any ActorBehavior] {
    component
  }

  public static func buildEither(second component: [any ActorBehavior]) -> [any ActorBehavior] {
    component
  }

  public static func buildExpression(_ expression: some ActorBehavior) -> [any ActorBehavior] {
    [expression]
  }
}
