// ActorPhysicsStateTests.swift
// Runtime tests for ActorPhysicsState

import SwiftGodot
import SwiftGodotBuilder

struct ActorPhysicsStateTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testInitialState", testInitialState),
      test("testResetClearsState", testResetClearsState),
      test("testKnockbackTimerDecays", testKnockbackTimerDecays),
      test("testKnockbackVelocityDecays", testKnockbackVelocityDecays),
      test("testKnockbackClearsWhenTimerExpires", testKnockbackClearsWhenTimerExpires),
      test("testInputDirectionStored", testInputDirectionStored),
      test("testGridMovementState", testGridMovementState),
      test("testClickToMoveTarget", testClickToMoveTarget),
      test("testFloorStateTracking", testFloorStateTracking),
    ]
  }

  func testInitialState() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    XCTAssertFalse(physics.isOnFloor)
    XCTAssertFalse(physics.wasOnFloor)
    XCTAssertFalse(physics.isOnWall)
    assertApproxEqual(physics.knockbackVelocity.x, Float(0))
    assertApproxEqual(physics.knockbackVelocity.y, Float(0))
    assertApproxEqual(physics.knockbackTimer, Double(0))
    assertApproxEqual(physics.currentVelocity.x, Float(0))
    assertApproxEqual(physics.currentVelocity.y, Float(0))
    XCTAssertFalse(physics.gridIsMoving)
    assertApproxEqual(physics.inputDirection.x, Float(0))
    assertApproxEqual(physics.inputDirection.y, Float(0))
    XCTAssertNil(physics.clickToMoveTarget)
  }

  func testResetClearsState() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    // Set some state
    physics.isOnFloor = true
    physics.wasOnFloor = true
    physics.isOnWall = true
    physics.knockbackVelocity = [100, 50]
    physics.knockbackTimer = 1.0
    physics.currentVelocity = [200, 100]
    physics.gridIsMoving = true
    physics.gridMoveProgress = 0.5
    physics.inputDirection = [1, 0]
    physics.clickToMoveTarget = [500, 300]

    // Reset
    physics.reset()

    // Verify cleared
    XCTAssertFalse(physics.isOnFloor)
    XCTAssertFalse(physics.wasOnFloor)
    XCTAssertFalse(physics.isOnWall)
    assertApproxEqual(physics.knockbackVelocity.x, Float(0))
    assertApproxEqual(physics.knockbackVelocity.y, Float(0))
    assertApproxEqual(physics.knockbackTimer, Double(0))
    assertApproxEqual(physics.currentVelocity.x, Float(0))
    assertApproxEqual(physics.currentVelocity.y, Float(0))
    XCTAssertFalse(physics.gridIsMoving)
    assertApproxEqual(physics.gridMoveProgress, Double(0))
    assertApproxEqual(physics.inputDirection.x, Float(0))
    assertApproxEqual(physics.inputDirection.y, Float(0))
    XCTAssertNil(physics.clickToMoveTarget)
  }

  func testKnockbackTimerDecays() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    physics.knockbackTimer = 1.0
    physics.knockbackVelocity = [100, 0]

    physics.updateTimers(0.5)

    assertApproxEqual(physics.knockbackTimer, 0.5)
  }

  func testKnockbackVelocityDecays() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    physics.knockbackTimer = 1.0
    physics.knockbackVelocity = [100, 0]

    // Use small delta so lerp weight (10.0 * delta) < 1.0
    physics.updateTimers(0.01)

    // Velocity should be less than initial due to lerp toward zero
    // With delta=0.01, weight=0.1, so 100 * 0.9 = 90
    XCTAssertLessThan(physics.knockbackVelocity.x, Float(100))
    XCTAssertGreaterThan(physics.knockbackVelocity.x, Float(0))
  }

  func testKnockbackClearsWhenTimerExpires() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    physics.knockbackTimer = 0.5
    physics.knockbackVelocity = [100, 50]

    // Update past timer expiry
    physics.updateTimers(1.0)

    assertApproxEqual(physics.knockbackVelocity.x, Float(0))
    assertApproxEqual(physics.knockbackVelocity.y, Float(0))
  }

  func testInputDirectionStored() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    physics.inputDirection = [1, -0.5]

    assertApproxEqual(physics.inputDirection.x, Float(1))
    assertApproxEqual(physics.inputDirection.y, Float(-0.5))
  }

  func testGridMovementState() {
    let config = ActorPhysicsConfig.grid(tileSize: [16, 16], moveDuration: 0.2)
    let physics = ActorPhysicsState(config: config)

    physics.gridStartPosition = [0, 0]
    physics.gridTargetPosition = [16, 0]
    physics.gridIsMoving = true
    physics.gridMoveProgress = 0.5

    XCTAssertTrue(physics.gridIsMoving)
    assertApproxEqual(physics.gridMoveProgress, 0.5)
    assertApproxEqual(physics.gridStartPosition.x, Float(0))
    assertApproxEqual(physics.gridTargetPosition.x, Float(16))
  }

  func testClickToMoveTarget() {
    let config = ActorPhysicsConfig.topDown()
    let physics = ActorPhysicsState(config: config)

    XCTAssertNil(physics.clickToMoveTarget)

    physics.clickToMoveTarget = [100, 200]
    XCTAssertNotNil(physics.clickToMoveTarget)
    assertApproxEqual(physics.clickToMoveTarget?.x ?? 0, Float(100))
    assertApproxEqual(physics.clickToMoveTarget?.y ?? 0, Float(200))

    physics.clickToMoveTarget = nil
    XCTAssertNil(physics.clickToMoveTarget)
  }

  func testFloorStateTracking() {
    let config = ActorPhysicsConfig.platformer()
    let physics = ActorPhysicsState(config: config)

    // Simulate landing
    physics.wasOnFloor = false
    physics.isOnFloor = true

    XCTAssertTrue(physics.isOnFloor)
    XCTAssertFalse(physics.wasOnFloor)

    // Next frame after landing
    physics.wasOnFloor = physics.isOnFloor
    XCTAssertTrue(physics.wasOnFloor)
    XCTAssertTrue(physics.isOnFloor)
  }
}
