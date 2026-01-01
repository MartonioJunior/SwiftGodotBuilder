// FacingTests.swift
// Runtime tests for Facing direction enum and related logic

import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct FacingTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testSignValues", testSignValues),
      test("testVerticalSignValues", testVerticalSignValues),
      test("testIsLeftRight", testIsLeftRight),
      test("testVectorCardinals", testVectorCardinals),
      test("testVectorDiagonals", testVectorDiagonals),
      test("testAngleValues", testAngleValues),
      test("testFromDirectionHorizontal", testFromDirectionHorizontal),
      test("testFromDirectionVertical", testFromDirectionVertical),
      test("testFromDirectionFourWay", testFromDirectionFourWay),
      test("testFromDirectionEightWay", testFromDirectionEightWay),
      test("testFromZeroVector", testFromZeroVector),
      test("testAttackPhaseProperties", testAttackPhaseProperties),
    ]
  }

  func testSignValues() {
    // Left-facing directions have sign -1
    assertApproxEqual(Facing.left.sign, Float(-1))
    assertApproxEqual(Facing.upLeft.sign, Float(-1))
    assertApproxEqual(Facing.downLeft.sign, Float(-1))

    // Right-facing directions have sign 1
    assertApproxEqual(Facing.right.sign, Float(1))
    assertApproxEqual(Facing.upRight.sign, Float(1))
    assertApproxEqual(Facing.downRight.sign, Float(1))

    // Pure vertical directions have sign 0
    assertApproxEqual(Facing.up.sign, Float(0))
    assertApproxEqual(Facing.down.sign, Float(0))
  }

  func testVerticalSignValues() {
    // Up-facing directions have verticalSign -1
    assertApproxEqual(Facing.up.verticalSign, Float(-1))
    assertApproxEqual(Facing.upLeft.verticalSign, Float(-1))
    assertApproxEqual(Facing.upRight.verticalSign, Float(-1))

    // Down-facing directions have verticalSign 1
    assertApproxEqual(Facing.down.verticalSign, Float(1))
    assertApproxEqual(Facing.downLeft.verticalSign, Float(1))
    assertApproxEqual(Facing.downRight.verticalSign, Float(1))

    // Pure horizontal directions have verticalSign 0
    assertApproxEqual(Facing.left.verticalSign, Float(0))
    assertApproxEqual(Facing.right.verticalSign, Float(0))
  }

  func testIsLeftRight() {
    // isLeft checks
    XCTAssertTrue(Facing.left.isLeft)
    XCTAssertTrue(Facing.upLeft.isLeft)
    XCTAssertTrue(Facing.downLeft.isLeft)
    XCTAssertFalse(Facing.right.isLeft)
    XCTAssertFalse(Facing.up.isLeft)
    XCTAssertFalse(Facing.down.isLeft)

    // isRight checks
    XCTAssertTrue(Facing.right.isRight)
    XCTAssertTrue(Facing.upRight.isRight)
    XCTAssertTrue(Facing.downRight.isRight)
    XCTAssertFalse(Facing.left.isRight)
    XCTAssertFalse(Facing.up.isRight)
    XCTAssertFalse(Facing.down.isRight)
  }

  func testVectorCardinals() {
    // Cardinal directions should be unit vectors
    assertApproxEqual(Facing.up.vector, Vector2(x: 0, y: -1))
    assertApproxEqual(Facing.down.vector, Vector2(x: 0, y: 1))
    assertApproxEqual(Facing.left.vector, Vector2(x: -1, y: 0))
    assertApproxEqual(Facing.right.vector, Vector2(x: 1, y: 0))
  }

  func testVectorDiagonals() {
    // Diagonal vectors should be normalized (length ~= 1)
    let sqrt2Inv = Float(1.0 / Foundation.sqrt(2.0))

    assertApproxEqual(Float(Facing.upLeft.vector.length()), Float(1.0))
    assertApproxEqual(Float(Facing.upRight.vector.length()), Float(1.0))
    assertApproxEqual(Float(Facing.downLeft.vector.length()), Float(1.0))
    assertApproxEqual(Float(Facing.downRight.vector.length()), Float(1.0))

    // Check components
    assertApproxEqual(Facing.upLeft.vector.x, -sqrt2Inv)
    assertApproxEqual(Facing.upLeft.vector.y, -sqrt2Inv)
    assertApproxEqual(Facing.downRight.vector.x, sqrt2Inv)
    assertApproxEqual(Facing.downRight.vector.y, sqrt2Inv)
  }

  func testAngleValues() {
    let pi = Float.pi

    // Right = 0 radians
    assertApproxEqual(Facing.right.angle, Float(0), epsilon: 0.01)

    // Down = pi/2
    assertApproxEqual(Facing.down.angle, pi / 2, epsilon: 0.01)

    // Up = -pi/2
    assertApproxEqual(Facing.up.angle, -pi / 2, epsilon: 0.01)

    // Left = +/- pi
    XCTAssertTrue(abs(Facing.left.angle) > pi - 0.1, "Left angle should be near +/- pi")
  }

  func testFromDirectionHorizontal() {
    // Horizontal mode only returns left or right
    let right = Facing.from(direction: [1, 0], axes: .horizontal)
    let left = Facing.from(direction: [-1, 0], axes: .horizontal)
    let diag = Facing.from(direction: [0.5, 0.9], axes: .horizontal)

    XCTAssertEqual(right, .right)
    XCTAssertEqual(left, .left)
    XCTAssertEqual(diag, .right, "Positive x should give right in horizontal mode")
  }

  func testFromDirectionVertical() {
    // Vertical mode only returns up or down
    let up = Facing.from(direction: [0, -1], axes: .vertical)
    let down = Facing.from(direction: [0, 1], axes: .vertical)
    let diag = Facing.from(direction: [0.9, 0.5], axes: .vertical)

    XCTAssertEqual(up, .up)
    XCTAssertEqual(down, .down)
    XCTAssertEqual(diag, .down, "Positive y should give down in vertical mode")
  }

  func testFromDirectionFourWay() {
    // Four-way picks dominant axis
    let right = Facing.from(direction: [1, 0.3], axes: .fourWay)
    let left = Facing.from(direction: [-1, 0.3], axes: .fourWay)
    let up = Facing.from(direction: [0.3, -1], axes: .fourWay)
    let down = Facing.from(direction: [0.3, 1], axes: .fourWay)

    XCTAssertEqual(right, .right)
    XCTAssertEqual(left, .left)
    XCTAssertEqual(up, .up)
    XCTAssertEqual(down, .down)
  }

  func testFromDirectionEightWay() {
    // Eight-way should return diagonals for diagonal inputs
    let upRight = Facing.from(direction: [1, -1], axes: .eightWay)
    let downLeft = Facing.from(direction: [-1, 1], axes: .eightWay)

    XCTAssertEqual(upRight, .upRight)
    XCTAssertEqual(downLeft, .downLeft)

    // Cardinal directions should still work
    let right = Facing.from(direction: [1, 0], axes: .eightWay)
    let up = Facing.from(direction: [0, -1], axes: .eightWay)

    XCTAssertEqual(right, .right)
    XCTAssertEqual(up, .up)
  }

  func testFromZeroVector() {
    // Zero or near-zero vectors should default to .right
    let zero = Facing.from(direction: [0, 0], axes: .eightWay)
    let tiny = Facing.from(direction: [0.05, 0.05], axes: .eightWay)

    XCTAssertEqual(zero, .right, "Zero vector should default to right")
    XCTAssertEqual(tiny, .right, "Tiny vector should default to right")
  }

  func testAttackPhaseProperties() {
    // Test AttackPhase enum properties
    XCTAssertFalse(AttackPhase.idle.isAttacking)
    XCTAssertTrue(AttackPhase.startup.isAttacking)
    XCTAssertTrue(AttackPhase.active.isAttacking)
    XCTAssertTrue(AttackPhase.recovery.isAttacking)

    XCTAssertFalse(AttackPhase.idle.hitboxActive)
    XCTAssertFalse(AttackPhase.startup.hitboxActive)
    XCTAssertTrue(AttackPhase.active.hitboxActive)
    XCTAssertFalse(AttackPhase.recovery.hitboxActive)
  }
}
