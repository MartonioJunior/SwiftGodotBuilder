// EventBusTests.swift
// Runtime tests for EventBus pub/sub system

import SwiftGodot
import SwiftGodotBuilder

// Test event types - each needs its own type to avoid cross-test pollution
enum TestEventA: Equatable { case ping, pong, value(Int) }
enum TestEventB: Equatable { case ping, pong }
enum TestEventC: Equatable { case ping }
enum TestEventD: Equatable { case value(Int) }
enum TestEventE: Equatable { case ping }
enum TestEventF: Equatable { case ping }
enum TestEventG: Equatable { case check }

struct EventBusTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testPublishCallsHandler", testPublishCallsHandler),
      test("testMultipleSubscribersReceiveEvents", testMultipleSubscribersReceiveEvents),
      test("testCancelRemovesHandler", testCancelRemovesHandler),
      test("testHandlerReceivesEventPayload", testHandlerReceivesEventPayload),
      test("testServiceLocatorReturnsSameBus", testServiceLocatorReturnsSameBus),
      test("testEmittableEventProtocol", testEmittableEventProtocol),
    ]
  }

  func testPublishCallsHandler() {
    let bus = ServiceLocator.resolve(TestEventA.self)
    var received = false
    let owner = Node2D()

    bus.onEach(owner: owner) { _ in
      received = true
    }

    bus.publish(TestEventA.ping)

    XCTAssertTrue(received, "Handler should be called on publish")
  }

  func testMultipleSubscribersReceiveEvents() {
    let bus = ServiceLocator.resolve(TestEventB.self)
    var count1 = 0
    var count2 = 0
    let owner = Node2D()

    bus.onEach(owner: owner) { _ in count1 += 1 }
    bus.onEach(owner: owner) { _ in count2 += 1 }

    bus.publish(TestEventB.ping)
    bus.publish(TestEventB.pong)

    XCTAssertEqual(count1, 2, "First subscriber should receive 2 events")
    XCTAssertEqual(count2, 2, "Second subscriber should receive 2 events")
  }

  func testCancelRemovesHandler() {
    let bus = ServiceLocator.resolve(TestEventC.self)
    var count = 0
    let owner = Node2D()

    let token = bus.onEach(owner: owner) { _ in
      count += 1
    }

    bus.publish(TestEventC.ping)
    XCTAssertEqual(count, 1)

    bus.cancel(token)
    bus.publish(TestEventC.ping)
    XCTAssertEqual(count, 1, "Handler should not be called after cancel")
  }

  func testHandlerReceivesEventPayload() {
    let bus = ServiceLocator.resolve(TestEventD.self)
    var receivedValue: Int?
    let owner = Node2D()

    bus.onEach(owner: owner) { event in
      if case let .value(v) = event {
        receivedValue = v
      }
    }

    bus.publish(TestEventD.value(42))

    XCTAssertEqual(receivedValue, 42, "Handler should receive event payload")
  }

  func testServiceLocatorReturnsSameBus() {
    let bus1 = ServiceLocator.resolve(TestEventG.self)
    let bus2 = ServiceLocator.resolve(TestEventG.self)

    // Both should be the same instance
    XCTAssertTrue(bus1 === bus2, "ServiceLocator should return same bus instance")
  }

  func testEmittableEventProtocol() {
    // Create a custom emittable event type
    enum GameTestEvent: EmittableEvent {
      case scored(Int)
    }

    var receivedScore: Int?
    let owner = Node2D()
    let bus = ServiceLocator.resolve(GameTestEvent.self)

    bus.onEach(owner: owner) { event in
      if case let .scored(score) = event {
        receivedScore = score
      }
    }

    // Use emit() on the event itself
    GameTestEvent.scored(100).emit()

    XCTAssertEqual(receivedScore, 100, "EmittableEvent.emit() should publish to bus")
  }
}
