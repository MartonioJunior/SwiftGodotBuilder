// BehaviorMachineTests.swift
// Runtime tests for BehaviorMachine state machine

import SwiftGodot
import SwiftGodotBuilder

// Test state enum
enum TestAIState: Hashable, Sendable {
  case idle
  case patrol
  case chase
  case attack
}

// Simple test behavior that tracks calls
struct CountingBehavior: ActorBehavior {
  static var processCount = 0
  static var enterCount = 0
  static var exitCount = 0

  static func reset() {
    processCount = 0
    enterCount = 0
    exitCount = 0
  }

  mutating func process(actor: ActorState, delta: Double) {
    CountingBehavior.processCount += 1
  }

  mutating func enter(actor: ActorState) {
    CountingBehavior.enterCount += 1
  }

  mutating func exit(actor: ActorState) {
    CountingBehavior.exitCount += 1
  }
}

struct BehaviorMachineTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testInitialState", testInitialState),
      test("testEnterCalledOnFirstProcess", testEnterCalledOnFirstProcess),
      test("testProcessCallsBehavior", testProcessCallsBehavior),
      test("testTransitionChangesState", testTransitionChangesState),
      test("testTransitionCallsExitAndEnter", testTransitionCallsExitAndEnter),
      test("testNoTransitionToSameState", testNoTransitionToSameState),
      test("testTransitionConditionChecked", testTransitionConditionChecked),
    ]
  }

  func testInitialState() {
    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        Idle()
      }
    }

    XCTAssertEqual(machine.currentState, TestAIState.idle)
  }

  func testEnterCalledOnFirstProcess() {
    CountingBehavior.reset()

    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        CountingBehavior()
      }
    }

    let actor = ActorState()

    XCTAssertEqual(CountingBehavior.enterCount, 0, "Enter not called before first process")

    machine.process(actor: actor, delta: 0.016)

    XCTAssertEqual(CountingBehavior.enterCount, 1, "Enter called on first process")
  }

  func testProcessCallsBehavior() {
    CountingBehavior.reset()

    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        CountingBehavior()
      }
    }

    let actor = ActorState()

    machine.process(actor: actor, delta: 0.016)
    machine.process(actor: actor, delta: 0.016)
    machine.process(actor: actor, delta: 0.016)

    XCTAssertEqual(CountingBehavior.processCount, 3)
  }

  func testTransitionChangesState() {
    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        Idle()
      }
      During(TestAIState.patrol) {
        Idle()
      }
    }

    let actor = ActorState()
    machine.process(actor: actor, delta: 0.016) // Enter initial state

    XCTAssertEqual(machine.currentState, TestAIState.idle)

    machine.transitionTo(TestAIState.patrol, actor: actor)

    XCTAssertEqual(machine.currentState, TestAIState.patrol)
  }

  func testTransitionCallsExitAndEnter() {
    CountingBehavior.reset()

    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        CountingBehavior()
      }
      During(TestAIState.patrol) {
        CountingBehavior()
      }
    }

    let actor = ActorState()
    machine.process(actor: actor, delta: 0.016) // Enter idle

    XCTAssertEqual(CountingBehavior.enterCount, 1)
    XCTAssertEqual(CountingBehavior.exitCount, 0)

    machine.transitionTo(TestAIState.patrol, actor: actor)

    XCTAssertEqual(CountingBehavior.exitCount, 1, "Exit called on old state")
    XCTAssertEqual(CountingBehavior.enterCount, 2, "Enter called on new state")
  }

  func testNoTransitionToSameState() {
    CountingBehavior.reset()

    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        CountingBehavior()
      }
    }

    let actor = ActorState()
    machine.process(actor: actor, delta: 0.016)

    let enterCountBefore = CountingBehavior.enterCount
    let exitCountBefore = CountingBehavior.exitCount

    machine.transitionTo(TestAIState.idle, actor: actor) // Same state

    XCTAssertEqual(CountingBehavior.enterCount, enterCountBefore, "Enter should not be called")
    XCTAssertEqual(CountingBehavior.exitCount, exitCountBefore, "Exit should not be called")
  }

  func testTransitionConditionChecked() {
    var shouldTransition = false

    let machine = BehaviorMachine<TestAIState>(initial: .idle) {
      During(TestAIState.idle) {
        Idle()
      }
      .transition(to: TestAIState.patrol) { _ in shouldTransition }

      During(TestAIState.patrol) {
        Idle()
      }
    }

    let actor = ActorState()

    // First process - condition is false
    machine.process(actor: actor, delta: 0.016)
    XCTAssertEqual(machine.currentState, TestAIState.idle)

    // Second process - condition still false
    machine.process(actor: actor, delta: 0.016)
    XCTAssertEqual(machine.currentState, TestAIState.idle)

    // Enable transition
    shouldTransition = true
    machine.process(actor: actor, delta: 0.016)
    XCTAssertEqual(machine.currentState, TestAIState.patrol)
  }
}
