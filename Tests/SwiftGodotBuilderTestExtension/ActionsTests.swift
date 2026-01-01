// ActionsTests.swift
// Runtime tests for Actions/Input system

import SwiftGodot
import SwiftGodotBuilder

struct ActionsTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testActionSpecCreation", testActionSpecCreation),
      test("testActionRecipesAxisUD", testActionRecipesAxisUD),
      test("testActionRecipesAxisLR", testActionRecipesAxisLR),
      test("testInputPhaseOptionSet", testInputPhaseOptionSet),
      test("testRuntimeActionCreation", testRuntimeActionCreation),
      test("testActionsBuilder", testActionsBuilder),
      test("testActionWithDeadzone", testActionWithDeadzone),
    ]
  }

  func testActionSpecCreation() {
    let spec = ActionSpec("test_action", deadzone: 0.3, events: [
      .key(.w),
      .joyButton(button: .dpadUp, device: 0)
    ])

    XCTAssertEqual(spec.name, "test_action")
    assertApproxEqual(spec.deadzone ?? 0, Double(0.3))
    XCTAssertEqual(spec.events.count, 2)
  }

  func testActionRecipesAxisUD() {
    let actions = ActionRecipes.axisUD(
      namePrefix: "move",
      device: 0,
      axis: .leftY,
      dz: 0.15,
      keyDown: .s,
      keyUp: .w
    )

    XCTAssertEqual(actions.count, 2)
    XCTAssertEqual(actions[0].name, "move_down")
    XCTAssertEqual(actions[1].name, "move_up")

    // Both should have deadzone
    assertApproxEqual(actions[0].deadzone ?? 0, Double(0.15))
    assertApproxEqual(actions[1].deadzone ?? 0, Double(0.15))

    // Down should have axis + key events
    XCTAssertEqual(actions[0].events.count, 2, "Should have axis + key")
    XCTAssertEqual(actions[1].events.count, 2, "Should have axis + key")
  }

  func testActionRecipesAxisLR() {
    let actions = ActionRecipes.axisLR(
      namePrefix: "move",
      device: 0,
      axis: .leftX,
      keyLeft: .a,
      keyRight: .d
    )

    XCTAssertEqual(actions.count, 2)
    XCTAssertEqual(actions[0].name, "move_left")
    XCTAssertEqual(actions[1].name, "move_right")
  }

  func testInputPhaseOptionSet() {
    // Test individual phases
    let pressed = InputPhase.pressed
    XCTAssertTrue(pressed.contains(.pressed))
    XCTAssertFalse(pressed.contains(.released))

    // Test combining phases
    let combined: InputPhase = [.pressed, .released]
    XCTAssertTrue(combined.contains(.pressed))
    XCTAssertTrue(combined.contains(.released))
    XCTAssertFalse(combined.contains(.echo))
  }

  func testRuntimeActionCreation() {
    // Test that RuntimeAction can be created
    let action = RuntimeAction(name: "test_runtime_action")
    XCTAssertNotNil(action.action, "RuntimeAction should have a StringName")

    // Test convenience function
    let action2 = Action("another_action")
    XCTAssertNotNil(action2.action)
  }

  func testActionsBuilder() {
    // Test the Actions builder DSL
    let actions = Actions {
      Action("jump") { Key(.space) }
      Action("fire") { MouseButton(1) }
    }

    XCTAssertEqual(actions.actions.count, 2)
    XCTAssertEqual(actions.actions[0].name, "jump")
    XCTAssertEqual(actions.actions[1].name, "fire")
    XCTAssertEqual(actions.actions[0].events.count, 1)
    XCTAssertEqual(actions.actions[1].events.count, 1)
  }

  func testActionWithDeadzone() {
    let action = Action("analog_action", deadzone: 0.25) {
      JoyAxis(.leftX, device: 0, 1.0)
    }

    XCTAssertEqual(action.name, "analog_action")
    assertApproxEqual(action.deadzone ?? 0, Double(0.25))
    XCTAssertEqual(action.events.count, 1)
  }
}
