// GSwitchTests.swift
// Runtime tests for GSwitch reactive switch/case container

import SwiftGodot
import SwiftGodotBuilder

struct GSwitchTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testSwitchContainerTypeForNode2D", testSwitchContainerTypeForNode2D),
      test("testSwitchContainerTypeForControl", testSwitchContainerTypeForControl),
      test("testSwitchNameModifier", testSwitchNameModifier),
      test("testSwitchWithMultipleCases", testSwitchWithMultipleCases),
      test("testSwitchDefaultContent", testSwitchDefaultContent),
    ]
  }

  func testSwitchContainerTypeForNode2D() {
    // Switch auto-detects container type from content
    // Node2D content should create a Node2D container
    let state = GState(wrappedValue: 1)

    let node = Switch(state) {
      Case(1) { Node2D$().name("content") }
    }.toNode()

    XCTAssertTrue(node is Node2D, "Switch with Node2D content should create Node2D container")
  }

  func testSwitchContainerTypeForControl() {
    // Control content should create a Container
    let state = GState(wrappedValue: 1)

    let node = Switch(state) {
      Case(1) { Label$().text("Hello") }
    }.toNode()

    XCTAssertTrue(node is Container, "Switch with Control content should create Container")
  }

  func testSwitchNameModifier() {
    let state = GState(wrappedValue: 1)

    let node = Switch(state) {
      Case(1) { Label$() }
    }
    .name("MySwitch")
    .toNode()

    XCTAssertEqual(node.name.description, "MySwitch", "Switch name modifier should set container name")
  }

  func testSwitchWithMultipleCases() {
    // Verify Switch handles multiple cases without crashing
    let state = GState(wrappedValue: "page1")

    let node = Switch(state) {
      Case("page1") { Label$().text("Page 1") }
      Case("page2") { Label$().text("Page 2") }
      Case("page3") { Label$().text("Page 3") }
    }
    .name("PageSwitch")
    .toNode()

    // Container should be created
    XCTAssertEqual(node.name.description, "PageSwitch", "Multi-case switch should work")
    XCTAssertTrue(node is Container, "Multi-case switch with Controls should create Container")
  }

  func testSwitchDefaultContent() {
    // Test that default content compiles and doesn't crash
    let state = GState(wrappedValue: 99) // No matching case

    let node = Switch(state) {
      Case(1) { Label$().text("One") }
      Case(2) { Label$().text("Two") }
    }
    .default {
      Label$().text("Unknown")
    }
    .name("WithDefault")
    .toNode()

    XCTAssertEqual(node.name.description, "WithDefault", "Switch with default should create container")
  }
}
