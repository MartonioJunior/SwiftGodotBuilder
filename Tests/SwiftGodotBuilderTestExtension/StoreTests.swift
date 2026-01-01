// StoreTests.swift
// Runtime tests for Store state management

import SwiftGodot
import SwiftGodotBuilder

// Test state and events
struct CounterState {
  var count = 0
  var lastEvent: String?
}

enum CounterEvent {
  case increment
  case decrement
  case reset
  case set(Int)
}

struct StoreTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testInitialState", testInitialState),
      test("testReducerTransformsState", testReducerTransformsState),
      test("testCommitMultipleEvents", testCommitMultipleEvents),
      test("testObserverReceivesInitialState", testObserverReceivesInitialState),
      test("testObserverReceivesUpdates", testObserverReceivesUpdates),
      test("testMultipleObservers", testMultipleObservers),
      test("testCancelStopsNotifications", testCancelStopsNotifications),
      test("testMiddlewareReceivesEvents", testMiddlewareReceivesEvents),
      test("testMiddlewareCanDispatch", testMiddlewareCanDispatch),
    ]
  }

  private func makeStore() -> Store<CounterState, CounterEvent> {
    Store(
      initialState: CounterState(),
      reducer: { state, event in
        switch event {
        case .increment:
          state.count += 1
          state.lastEvent = "increment"
        case .decrement:
          state.count -= 1
          state.lastEvent = "decrement"
        case .reset:
          state.count = 0
          state.lastEvent = "reset"
        case let .set(value):
          state.count = value
          state.lastEvent = "set"
        }
      }
    )
  }

  func testInitialState() {
    let store = makeStore()

    XCTAssertEqual(store.state.count, 0)
    XCTAssertNil(store.state.lastEvent)
  }

  func testReducerTransformsState() {
    let store = makeStore()

    store.commit(.increment)

    XCTAssertEqual(store.state.count, 1)
    XCTAssertEqual(store.state.lastEvent, "increment")
  }

  func testCommitMultipleEvents() {
    let store = makeStore()

    store.commit(.increment)
    store.commit(.increment)
    store.commit(.increment)
    store.commit(.decrement)

    XCTAssertEqual(store.state.count, 2)
  }

  func testObserverReceivesInitialState() {
    let store = makeStore()
    store.commit(.set(42))

    var observedCount: Int?
    store.observe { state in
      observedCount = state.count
    }

    XCTAssertEqual(observedCount, 42, "Observer should receive current state immediately")
  }

  func testObserverReceivesUpdates() {
    let store = makeStore()
    var updateCount = 0
    var lastObservedCount = 0

    store.observe { state in
      updateCount += 1
      lastObservedCount = state.count
    }

    XCTAssertEqual(updateCount, 1, "Initial observation")

    store.commit(.increment)
    XCTAssertEqual(updateCount, 2)
    XCTAssertEqual(lastObservedCount, 1)

    store.commit(.increment)
    XCTAssertEqual(updateCount, 3)
    XCTAssertEqual(lastObservedCount, 2)
  }

  func testMultipleObservers() {
    let store = makeStore()
    var count1 = 0
    var count2 = 0

    store.observe { _ in count1 += 1 }
    store.observe { _ in count2 += 1 }

    store.commit(.increment)

    XCTAssertEqual(count1, 2, "First observer: initial + update")
    XCTAssertEqual(count2, 2, "Second observer: initial + update")
  }

  func testCancelStopsNotifications() {
    let store = makeStore()
    var count = 0

    let token = store.observe { _ in count += 1 }
    XCTAssertEqual(count, 1, "Initial observation")

    store.commit(.increment)
    XCTAssertEqual(count, 2)

    store.cancel(token)

    store.commit(.increment)
    XCTAssertEqual(count, 2, "No more updates after cancel")
  }

  func testMiddlewareReceivesEvents() {
    var receivedEvents: [String] = []

    let middleware = Middleware<CounterState, CounterEvent> { event, _, _ in
      switch event {
      case .increment: receivedEvents.append("increment")
      case .decrement: receivedEvents.append("decrement")
      case .reset: receivedEvents.append("reset")
      case .set: receivedEvents.append("set")
      }
    }

    let store = Store(
      initialState: CounterState(),
      reducer: { _, _ in },
      middleware: [middleware]
    )

    store.commit(.increment)
    store.commit(.decrement)

    XCTAssertEqual(receivedEvents.count, 2)
    XCTAssertEqual(receivedEvents[0], "increment")
    XCTAssertEqual(receivedEvents[1], "decrement")
  }

  func testMiddlewareCanDispatch() {
    // Middleware that dispatches a different event type to avoid recursion
    let incrementToSetMiddleware = Middleware<CounterState, CounterEvent> { event, state, dispatch in
      if case .increment = event {
        // Dispatch a set event instead of increment to avoid infinite recursion
        dispatch(.set(state.count + 10))
      }
    }

    let store = Store(
      initialState: CounterState(),
      reducer: { state, event in
        switch event {
        case .increment: state.count += 1
        case let .set(v): state.count = v
        default: break
        }
      },
      middleware: [incrementToSetMiddleware]
    )

    store.commit(.increment)

    // Reducer increments to 1, then middleware dispatches set(11)
    XCTAssertEqual(store.state.count, 11, "Middleware should dispatch additional event")
  }
}
