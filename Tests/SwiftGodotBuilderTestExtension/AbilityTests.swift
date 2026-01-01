// AbilityTests.swift
// Runtime tests for Actor abilities (Jump, Dash, WallJump)

import SwiftGodot
import SwiftGodotBuilder

struct AbilityTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      // JumpConfig tests
      test("testJumpConfigDefaults", testJumpConfigDefaults),
      test("testJumpConfigCustom", testJumpConfigCustom),
      test("testJumpAbilityInitialState", testJumpAbilityInitialState),
      test("testJumpAbilityReset", testJumpAbilityReset),

      // DashConfig tests
      test("testDashConfigDefaults", testDashConfigDefaults),
      test("testDashConfigCustom", testDashConfigCustom),
      test("testDashAbilityInitialState", testDashAbilityInitialState),
      test("testDashAbilityReset", testDashAbilityReset),

      // WallJumpConfig tests
      test("testWallJumpConfigDefaults", testWallJumpConfigDefaults),
      test("testWallJumpConfigCustom", testWallJumpConfigCustom),
      test("testWallJumpAbilityInitialState", testWallJumpAbilityInitialState),
      test("testWallJumpGravityMultiplier", testWallJumpGravityMultiplier),

      // AbilitySlot tests
      test("testAbilitySlotValues", testAbilitySlotValues),
      test("testAbilitySlotCaseIterable", testAbilitySlotCaseIterable),
    ]
  }

  // MARK: - JumpConfig Tests

  func testJumpConfigDefaults() {
    let config = JumpConfig.default

    assertApproxEqual(config.jumpSpeed, Float(130))
    assertApproxEqual(config.minJumpSpeed, Float(60))
    assertApproxEqual(config.coyoteTime, Double(0.1))
    assertApproxEqual(config.jumpBufferTime, Double(0.1))
    XCTAssertTrue(config.doubleJumpEnabled)
  }

  func testJumpConfigCustom() {
    let config = JumpConfig(
      jumpSpeed: 200,
      minJumpSpeed: 100,
      coyoteTime: 0.2,
      jumpBufferTime: 0.15,
      doubleJumpEnabled: false
    )

    assertApproxEqual(config.jumpSpeed, Float(200))
    assertApproxEqual(config.minJumpSpeed, Float(100))
    assertApproxEqual(config.coyoteTime, Double(0.2))
    assertApproxEqual(config.jumpBufferTime, Double(0.15))
    XCTAssertFalse(config.doubleJumpEnabled)
  }

  func testJumpAbilityInitialState() {
    let ability = JumpAbility()

    XCTAssertFalse(ability.isActive, "Jump is instant, not sustained")
    XCTAssertFalse(ability.isOnCooldown, "Jump has no cooldown")
  }

  func testJumpAbilityReset() {
    let ability = JumpAbility()

    // Request a jump then reset
    ability.requestJump()
    ability.reset()

    // After reset, ability should be in clean state
    XCTAssertFalse(ability.isActive)
    XCTAssertFalse(ability.isOnCooldown)
  }

  // MARK: - DashConfig Tests

  func testDashConfigDefaults() {
    let config = DashConfig.default

    assertApproxEqual(config.speed, Float(200))
    assertApproxEqual(config.duration, Double(0.15))
    assertApproxEqual(config.cooldown, Double(0.5))
  }

  func testDashConfigCustom() {
    let config = DashConfig(
      speed: 300,
      duration: 0.2,
      cooldown: 1.0
    )

    assertApproxEqual(config.speed, Float(300))
    assertApproxEqual(config.duration, Double(0.2))
    assertApproxEqual(config.cooldown, Double(1.0))
  }

  func testDashAbilityInitialState() {
    let ability = DashAbility()

    XCTAssertFalse(ability.isActive)
    XCTAssertFalse(ability.isOnCooldown)
  }

  func testDashAbilityReset() {
    let ability = DashAbility()

    // Reset should clear all state
    ability.reset()

    XCTAssertFalse(ability.isActive)
    XCTAssertFalse(ability.isOnCooldown)
  }

  // MARK: - WallJumpConfig Tests

  func testWallJumpConfigDefaults() {
    let config = WallJumpConfig.default

    assertApproxEqual(config.wallSlideGravityMultiplier, Float(0.3))
    assertApproxEqual(config.wallJumpHorizontalSpeed, Float(80))
    assertApproxEqual(config.wallJumpVerticalSpeed, Float(130))
  }

  func testWallJumpConfigCustom() {
    let config = WallJumpConfig(
      wallSlideGravityMultiplier: 0.5,
      wallJumpHorizontalSpeed: 100,
      wallJumpVerticalSpeed: 150
    )

    assertApproxEqual(config.wallSlideGravityMultiplier, Float(0.5))
    assertApproxEqual(config.wallJumpHorizontalSpeed, Float(100))
    assertApproxEqual(config.wallJumpVerticalSpeed, Float(150))
  }

  func testWallJumpAbilityInitialState() {
    let ability = WallJumpAbility()

    XCTAssertFalse(ability.isActive, "Not wall sliding initially")
    XCTAssertFalse(ability.isOnCooldown, "Wall jump has no cooldown")
  }

  func testWallJumpGravityMultiplier() {
    let config = WallJumpConfig(wallSlideGravityMultiplier: 0.25)
    let ability = WallJumpAbility(config: config)

    // When not wall sliding, multiplier is 1.0
    assertApproxEqual(ability.getGravityMultiplier(), Float(1.0))

    // After reset, still 1.0
    ability.reset()
    assertApproxEqual(ability.getGravityMultiplier(), Float(1.0))
  }

  // MARK: - AbilitySlot Tests

  func testAbilitySlotValues() {
    XCTAssertEqual(AbilitySlot.primary.rawValue, 0)
    XCTAssertEqual(AbilitySlot.secondary.rawValue, 1)
    XCTAssertEqual(AbilitySlot.tertiary.rawValue, 2)
    XCTAssertEqual(AbilitySlot.quaternary.rawValue, 3)
  }

  func testAbilitySlotCaseIterable() {
    let allSlots = AbilitySlot.allCases
    XCTAssertEqual(allSlots.count, 4)
  }
}
