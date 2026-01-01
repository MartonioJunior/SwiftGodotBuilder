// ParticleConfigTests.swift
// Runtime tests for ParticleConfig presets and modifiers

import SwiftGodot
import SwiftGodotBuilder

struct ParticleConfigTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testExplosionPreset", testExplosionPreset),
      test("testSparklePreset", testSparklePreset),
      test("testDustPreset", testDustPreset),
      test("testSplatterPreset", testSplatterPreset),
      test("testSmokePreset", testSmokePreset),
      test("testWithColorModifier", testWithColorModifier),
      test("testWithAmountModifier", testWithAmountModifier),
      test("testPresetValuesInRange", testPresetValuesInRange),
    ]
  }

  func testExplosionPreset() {
    let config = ParticleConfig.explosion

    XCTAssertEqual(config.amount, 20)
    assertApproxEqual(config.lifetime, Double(0.6))
    assertApproxEqual(config.explosiveness, Double(1.0), "Explosion should emit all at once")
    assertApproxEqual(config.spread, Double(180), "Explosion should spread in all directions")
    XCTAssertGreaterThan(config.initialVelocityMin, Double(0))
    XCTAssertGreaterThan(config.initialVelocityMax, config.initialVelocityMin)
  }

  func testSparklePreset() {
    let config = ParticleConfig.sparkle

    XCTAssertEqual(config.amount, 8)
    assertApproxEqual(config.explosiveness, Double(0.0), "Sparkle should emit steadily")
    assertApproxEqual(config.spread, Double(30), "Sparkle should have narrow spread")
    // Negative gravity = particles float upward
    XCTAssertLessThan(config.gravity.y, Float(0), "Sparkle should have negative gravity")
  }

  func testDustPreset() {
    let config = ParticleConfig.dust

    XCTAssertEqual(config.amount, 6)
    assertApproxEqual(config.lifetime, Double(0.4), "Dust should be short-lived")
    assertApproxEqual(config.explosiveness, Double(0.8), "Dust should emit quickly")
    XCTAssertGreaterThan(config.gravity.y, Float(0), "Dust should fall with gravity")
  }

  func testSplatterPreset() {
    let config = ParticleConfig.splatter

    XCTAssertEqual(config.amount, 12)
    assertApproxEqual(config.explosiveness, Double(1.0), "Splatter should emit all at once")
    assertApproxEqual(config.spread, Double(90))

    // Check red color
    XCTAssertGreaterThan(config.color.red, 0.5)
    XCTAssertLessThan(config.color.green, 0.3)
    XCTAssertLessThan(config.color.blue, 0.3)
  }

  func testSmokePreset() {
    let config = ParticleConfig.smoke

    XCTAssertEqual(config.amount, 10)
    assertApproxEqual(config.lifetime, Double(1.5), "Smoke should be long-lived")
    assertApproxEqual(config.explosiveness, Double(0.0), "Smoke should emit steadily")
    XCTAssertLessThan(config.gravity.y, Float(0), "Smoke should rise")

    // Check gray color with transparency
    assertApproxEqual(config.color.red, 0.3, epsilon: 0.1)
    assertApproxEqual(config.color.green, 0.3, epsilon: 0.1)
    assertApproxEqual(config.color.blue, 0.3, epsilon: 0.1)
    assertApproxEqual(config.color.alpha, 0.5, epsilon: 0.1)
  }

  func testWithColorModifier() {
    let original = ParticleConfig.explosion
    let modified = original.withColor(.blue)

    // Color should change
    assertApproxEqual(modified.color.blue, Float(1.0))

    // Other properties should be preserved
    XCTAssertEqual(modified.amount, original.amount)
    assertApproxEqual(modified.lifetime, original.lifetime)
    assertApproxEqual(modified.explosiveness, original.explosiveness)
    assertApproxEqual(modified.spread, original.spread)
    assertApproxEqual(modified.initialVelocityMin, original.initialVelocityMin)
    assertApproxEqual(modified.initialVelocityMax, original.initialVelocityMax)
    assertApproxEqual(modified.gravity.x, original.gravity.x)
    assertApproxEqual(modified.gravity.y, original.gravity.y)
  }

  func testWithAmountModifier() {
    let original = ParticleConfig.sparkle
    let modified = original.withAmount(50)

    // Amount should change
    XCTAssertEqual(modified.amount, 50)

    // Other properties should be preserved
    assertApproxEqual(modified.lifetime, original.lifetime)
    assertApproxEqual(modified.explosiveness, original.explosiveness)
    assertApproxEqual(modified.spread, original.spread)
    assertApproxEqual(modified.color.red, original.color.red)
    assertApproxEqual(modified.color.green, original.color.green)
    assertApproxEqual(modified.color.blue, original.color.blue)
  }

  func testPresetValuesInRange() {
    let presets: [ParticleConfig] = [.explosion, .sparkle, .dust, .splatter, .smoke]

    for config in presets {
      // Amount should be positive
      XCTAssertGreaterThan(config.amount, 0, "Amount should be positive")

      // Lifetime should be positive
      XCTAssertGreaterThan(config.lifetime, 0.0, "Lifetime should be positive")

      // Explosiveness should be 0.0-1.0
      XCTAssertGreaterThanOrEqual(config.explosiveness, 0.0)
      XCTAssertLessThanOrEqual(config.explosiveness, 1.0)

      // Spread should be 0-360
      XCTAssertGreaterThanOrEqual(config.spread, 0.0)
      XCTAssertLessThanOrEqual(config.spread, 360.0)

      // Min velocity should be <= max velocity
      XCTAssertLessThanOrEqual(config.initialVelocityMin, config.initialVelocityMax)

      // Color alpha should be valid
      XCTAssertGreaterThan(config.color.alpha, Float(0))
      XCTAssertLessThanOrEqual(config.color.alpha, Float(1))
    }
  }
}
