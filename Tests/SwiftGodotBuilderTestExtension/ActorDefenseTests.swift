// ActorDefenseTests.swift
// Runtime tests for ActorDefenseState

import SwiftGodot
import SwiftGodotBuilder

struct ActorDefenseTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testInitialHealth", testInitialHealth),
      test("testTakeDamage", testTakeDamage),
      test("testDamageWhileInvincible", testDamageWhileInvincible),
      test("testDeathTriggersAtZeroHealth", testDeathTriggersAtZeroHealth),
      test("testInvincibilityAfterDamage", testInvincibilityAfterDamage),
      test("testInvincibilityTimerExpires", testInvincibilityTimerExpires),
      test("testHealClampsToMaxHealth", testHealClampsToMaxHealth),
      test("testResetRestoresFullHealth", testResetRestoresFullHealth),
      test("testCannotDamageWhileDying", testCannotDamageWhileDying),
    ]
  }

  func testInitialHealth() {
    let config = ActorDefenseConfig(maxHealth: 100)
    let defense = ActorDefenseState(config: config)

    XCTAssertEqual(defense.health, 100)
    XCTAssertEqual(defense.maxHealth, 100)
    XCTAssertFalse(defense.isInvincible)
    XCTAssertFalse(defense.isDying)
  }

  func testTakeDamage() {
    let config = ActorDefenseConfig(maxHealth: 100, invincibilityDuration: 0)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    defense.takeDamage(25, coreState: actorState, physicsState: nil)

    XCTAssertEqual(defense.health, 75)
    XCTAssertFalse(defense.isDying)
  }

  func testDamageWhileInvincible() {
    let config = ActorDefenseConfig(maxHealth: 100, invincibilityDuration: 1.0)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    // Take initial damage - triggers invincibility
    defense.takeDamage(25, coreState: actorState, physicsState: nil)
    XCTAssertEqual(defense.health, 75)
    XCTAssertTrue(defense.isInvincible)

    // Try to take more damage while invincible
    defense.takeDamage(25, coreState: actorState, physicsState: nil)
    XCTAssertEqual(defense.health, 75, "Health should not change while invincible")
  }

  func testDeathTriggersAtZeroHealth() {
    let config = ActorDefenseConfig(maxHealth: 50, invincibilityDuration: 0)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    defense.takeDamage(50, coreState: actorState, physicsState: nil)

    XCTAssertEqual(defense.health, 0)
    XCTAssertTrue(defense.isDying)
  }

  func testInvincibilityAfterDamage() {
    let config = ActorDefenseConfig(maxHealth: 100, invincibilityDuration: 0.5)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    defense.takeDamage(10, coreState: actorState, physicsState: nil)

    XCTAssertTrue(defense.isInvincible)
    XCTAssertEqual(defense.invincibilityTimer, 0.5)
  }

  func testInvincibilityTimerExpires() {
    let config = ActorDefenseConfig(maxHealth: 100, invincibilityDuration: 0.5)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    defense.takeDamage(10, coreState: actorState, physicsState: nil)
    XCTAssertTrue(defense.isInvincible)

    // Simulate time passing
    defense.updateTimers(0.6)

    XCTAssertFalse(defense.isInvincible)
    XCTAssertLessThan(defense.invincibilityTimer, 0)
  }

  func testHealClampsToMaxHealth() {
    let config = ActorDefenseConfig(maxHealth: 100)
    let defense = ActorDefenseState(config: config)

    // Reduce health first
    defense.health = 50

    // Heal more than missing
    defense.heal(75)

    XCTAssertEqual(defense.health, 100, "Health should clamp to maxHealth")
  }

  func testResetRestoresFullHealth() {
    let config = ActorDefenseConfig(maxHealth: 100, invincibilityDuration: 1.0)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    // Damage and mark as dying
    defense.takeDamage(100, coreState: actorState, physicsState: nil)
    XCTAssertTrue(defense.isDying)
    XCTAssertEqual(defense.health, 0)

    // Reset for pooling
    defense.reset()

    XCTAssertEqual(defense.health, 100)
    XCTAssertFalse(defense.isDying)
    XCTAssertFalse(defense.isInvincible)
  }

  func testCannotDamageWhileDying() {
    let config = ActorDefenseConfig(maxHealth: 100, invincibilityDuration: 0)
    let defense = ActorDefenseState(config: config)
    let actorState = ActorState()

    // Kill the actor
    defense.takeDamage(100, coreState: actorState, physicsState: nil)
    XCTAssertTrue(defense.isDying)

    // Try to damage again (shouldn't work)
    defense.health = 50 // Manually set to test guard
    defense.takeDamage(25, coreState: actorState, physicsState: nil)
    XCTAssertEqual(defense.health, 50, "Damage should be blocked while dying")
  }
}
