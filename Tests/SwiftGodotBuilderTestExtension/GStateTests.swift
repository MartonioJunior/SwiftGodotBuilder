// GStateTests.swift
// Runtime tests for GState public API

import SwiftGodot
import SwiftGodotBuilder

struct GStateTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testInitialValue", testInitialValue),
      test("testValueChange", testValueChange),
      test("testValueEquality", testValueEquality),
      test("testComputedState", testComputedState),
      test("testComputedUpdatesOnSourceChange", testComputedUpdatesOnSourceChange),
      test("testComputedChaining", testComputedChaining),
    ]
  }

  func testInitialValue() {
    let state = GState<Int>(wrappedValue: 42)
    XCTAssertEqual(state.wrappedValue, 42)
  }

  func testValueChange() {
    let state = GState<Int>(wrappedValue: 0)
    state.wrappedValue = 10
    XCTAssertEqual(state.wrappedValue, 10)
  }

  func testValueEquality() {
    let state = GState<Int>(wrappedValue: 5)

    // Setting to same value should work (no crash)
    state.wrappedValue = 5
    XCTAssertEqual(state.wrappedValue, 5)

    // Setting to different value should work
    state.wrappedValue = 10
    XCTAssertEqual(state.wrappedValue, 10)
  }

  func testComputedState() {
    let source = GState<Int>(wrappedValue: 5)
    let doubled = source.computed { $0 * 2 }

    XCTAssertEqual(doubled.wrappedValue, 10)
  }

  func testComputedUpdatesOnSourceChange() {
    let source = GState<Int>(wrappedValue: 3)
    let squared = source.computed { $0 * $0 }

    XCTAssertEqual(squared.wrappedValue, 9)

    source.wrappedValue = 4
    XCTAssertEqual(squared.wrappedValue, 16, "Computed state should update when source changes")
  }

  func testComputedChaining() {
    let source = GState<Int>(wrappedValue: 2)
    let doubled = source.computed { $0 * 2 }
    let quadrupled = doubled.computed { $0 * 2 }

    XCTAssertEqual(quadrupled.wrappedValue, 8)

    source.wrappedValue = 3
    XCTAssertEqual(doubled.wrappedValue, 6)
    XCTAssertEqual(quadrupled.wrappedValue, 12, "Chained computed should update")
  }
}
