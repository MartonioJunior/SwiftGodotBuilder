// ActorPhysicsConfigTests.swift
// Runtime tests for ActorPhysicsConfig and MovementModel

import SwiftGodot
import SwiftGodotBuilder

struct ActorPhysicsConfigTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testDefaultValues", testDefaultValues),
      test("testPlatformerPreset", testPlatformerPreset),
      test("testTopDownPreset", testTopDownPreset),
      test("testVelocityPreset", testVelocityPreset),
      test("testGridPreset", testGridPreset),
      test("testMovementModelEquality", testMovementModelEquality),
      test("testCustomConfig", testCustomConfig),
    ]
  }

  func testDefaultValues() {
    let config = ActorPhysicsConfig()

    // Check defaults
    assertApproxEqual(config.speed, Float(60))
    XCTAssertNil(config.gravity, "Default gravity should be nil (use world gravity)")
    assertApproxEqual(config.knockbackStrength, Float(80))
    assertApproxEqual(config.knockbackRecoveryTime, Double(0.15))

    // Default movement model is physics
    if case .physics = config.movementModel {
      XCTAssertTrue(true)
    } else {
      XCTFail("Default movement model should be .physics")
    }

    // Default facing is horizontal
    XCTAssertEqual(config.facingAxes, .horizontal)
  }

  func testPlatformerPreset() {
    let config = ActorPhysicsConfig.platformer(speed: 100, gravity: 600)

    assertApproxEqual(config.speed, Float(100))
    assertApproxEqual(config.gravity ?? 0, Float(600))
    XCTAssertEqual(config.facingAxes, .horizontal)

    if case .physics = config.movementModel {
      XCTAssertTrue(true)
    } else {
      XCTFail("Platformer should use physics movement model")
    }
  }

  func testTopDownPreset() {
    let config = ActorPhysicsConfig.topDown(speed: 120, facingAxes: .fourWay)

    assertApproxEqual(config.speed, Float(120))
    assertApproxEqual(config.gravity ?? -1, Float(0), "Top-down should have no gravity")
    XCTAssertEqual(config.facingAxes, .fourWay)

    if case .velocity(let accel, let decel) = config.movementModel {
      assertApproxEqual(accel, Float(0))
      assertApproxEqual(decel, Float(0))
    } else {
      XCTFail("Top-down should use velocity movement model")
    }
  }

  func testVelocityPreset() {
    let config = ActorPhysicsConfig.velocity(
      speed: 150,
      acceleration: 500,
      deceleration: 300,
      facingAxes: .eightWay
    )

    assertApproxEqual(config.speed, Float(150))
    assertApproxEqual(config.gravity ?? -1, Float(0))
    XCTAssertEqual(config.facingAxes, .eightWay)

    if case .velocity(let accel, let decel) = config.movementModel {
      assertApproxEqual(accel, Float(500))
      assertApproxEqual(decel, Float(300))
    } else {
      XCTFail("Velocity preset should use velocity movement model")
    }
  }

  func testGridPreset() {
    let config = ActorPhysicsConfig.grid(
      tileSize: [32, 32],
      moveDuration: 0.2,
      facingAxes: .fourWay
    )

    assertApproxEqual(config.speed, Float(0), "Grid mode doesn't use speed")
    assertApproxEqual(config.gravity ?? -1, Float(0))
    XCTAssertEqual(config.facingAxes, .fourWay)

    if case .grid(let tileSize, let duration) = config.movementModel {
      assertApproxEqual(tileSize.x, Float(32))
      assertApproxEqual(tileSize.y, Float(32))
      assertApproxEqual(duration, Double(0.2))
    } else {
      XCTFail("Grid preset should use grid movement model")
    }
  }

  func testMovementModelEquality() {
    // Physics models are equal
    let physics1 = MovementModel.physics
    let physics2 = MovementModel.physics
    XCTAssertEqual(physics1, physics2)

    // Velocity models with same params are equal
    let vel1 = MovementModel.velocity(acceleration: 100, deceleration: 50)
    let vel2 = MovementModel.velocity(acceleration: 100, deceleration: 50)
    XCTAssertEqual(vel1, vel2)

    // Velocity models with different params are not equal
    let vel3 = MovementModel.velocity(acceleration: 200, deceleration: 50)
    XCTAssertNotEqual(vel1, vel3)

    // Grid models with same params are equal
    let grid1 = MovementModel.grid(tileSize: [16, 16], moveDuration: 0.1)
    let grid2 = MovementModel.grid(tileSize: [16, 16], moveDuration: 0.1)
    XCTAssertEqual(grid1, grid2)

    // Different model types are not equal
    XCTAssertNotEqual(physics1, MovementModel.velocity())
  }

  func testCustomConfig() {
    let config = ActorPhysicsConfig(
      movementModel: .velocity(acceleration: 1000, deceleration: 800),
      facingAxes: .eightWay,
      speed: 200,
      gravity: 0,
      knockbackStrength: 150,
      knockbackRecoveryTime: 0.3
    )

    assertApproxEqual(config.speed, Float(200))
    assertApproxEqual(config.gravity ?? -1, Float(0))
    assertApproxEqual(config.knockbackStrength, Float(150))
    assertApproxEqual(config.knockbackRecoveryTime, Double(0.3))
    XCTAssertEqual(config.facingAxes, .eightWay)
  }
}
