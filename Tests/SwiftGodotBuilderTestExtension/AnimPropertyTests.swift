// AnimPropertyTests.swift
// Runtime tests for Anim enum property name and value mappings

import SwiftGodot
import SwiftGodotBuilder

struct AnimPropertyTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testScalePropertyNames", testScalePropertyNames),
      test("testPositionPropertyNames", testPositionPropertyNames),
      test("testRotationPropertyNames", testRotationPropertyNames),
      test("testColorPropertyNames", testColorPropertyNames),
      test("testOtherPropertyNames", testOtherPropertyNames),
      test("testCustomProperty", testCustomProperty),
      test("testValueVariants", testValueVariants),
    ]
  }

  func testScalePropertyNames() {
    XCTAssertEqual(Anim.scale([1, 1]).propertyName, "scale")
    XCTAssertEqual(Anim.scaleX(1).propertyName, "scale:x")
    XCTAssertEqual(Anim.scaleY(1).propertyName, "scale:y")
  }

  func testPositionPropertyNames() {
    XCTAssertEqual(Anim.position([0, 0]).propertyName, "position")
    XCTAssertEqual(Anim.positionX(0).propertyName, "position:x")
    XCTAssertEqual(Anim.positionY(0).propertyName, "position:y")
    XCTAssertEqual(Anim.globalPosition([0, 0]).propertyName, "global_position")
    XCTAssertEqual(Anim.offset([0, 0]).propertyName, "offset")
  }

  func testRotationPropertyNames() {
    XCTAssertEqual(Anim.rotation(0).propertyName, "rotation")
    XCTAssertEqual(Anim.rotationDegrees(0).propertyName, "rotation_degrees")
  }

  func testColorPropertyNames() {
    XCTAssertEqual(Anim.color(.white).propertyName, "color")
    XCTAssertEqual(Anim.modulate(.white).propertyName, "modulate")
    XCTAssertEqual(Anim.alpha(1).propertyName, "modulate:a")
    XCTAssertEqual(Anim.selfModulate(.white).propertyName, "self_modulate")
    XCTAssertEqual(Anim.selfAlpha(1).propertyName, "self_modulate:a")
  }

  func testOtherPropertyNames() {
    XCTAssertEqual(Anim.size([100, 100]).propertyName, "size")
    XCTAssertEqual(Anim.minSize([50, 50]).propertyName, "custom_minimum_size")
    XCTAssertEqual(Anim.value(0.5).propertyName, "value")
    XCTAssertEqual(Anim.ratio(0.5).propertyName, "ratio")
    XCTAssertEqual(Anim.zoom([1, 1]).propertyName, "zoom")
    XCTAssertEqual(Anim.energy(1).propertyName, "energy")
    XCTAssertEqual(Anim.width(2).propertyName, "width")
    XCTAssertEqual(Anim.frame(0).propertyName, "frame")
    XCTAssertEqual(Anim.pivotOffset([0, 0]).propertyName, "pivot_offset")
    XCTAssertEqual(Anim.skew(0).propertyName, "skew")
    XCTAssertEqual(Anim.volumeDb(-10).propertyName, "volume_db")
    XCTAssertEqual(Anim.pitchScale(1).propertyName, "pitch_scale")
  }

  func testCustomProperty() {
    let custom = Anim.custom(property: "my_property", value: Variant(42))
    XCTAssertEqual(custom.propertyName, "my_property")

    // Value should be retrievable
    let intVal = Int(custom.value) ?? 0
    XCTAssertEqual(intVal, 42)
  }

  func testValueVariants() {
    // Test that values are correctly wrapped as Variants

    // Vector2 values
    let scaleAnim = Anim.scale([2, 3])
    if let vec = Vector2(scaleAnim.value) {
      assertApproxEqual(vec.x, Float(2))
      assertApproxEqual(vec.y, Float(3))
    } else {
      XCTFail("Scale value should be Vector2")
    }

    // Float values
    let rotAnim = Anim.rotation(1.5)
    if let rot = Float(rotAnim.value) {
      assertApproxEqual(rot, Float(1.5))
    } else {
      XCTFail("Rotation value should be Float")
    }

    // Double values
    let valueAnim = Anim.value(0.75)
    if let val = Double(valueAnim.value) {
      assertApproxEqual(val, Double(0.75))
    } else {
      XCTFail("Value should be Double")
    }

    // Int values (frame)
    let frameAnim = Anim.frame(5)
    if let frame = Int(frameAnim.value) {
      XCTAssertEqual(frame, 5)
    } else {
      XCTFail("Frame value should be Int")
    }

    // Color values
    let colorAnim = Anim.modulate(Color(r: 1, g: 0.5, b: 0.25, a: 0.8))
    if let col = Color(colorAnim.value) {
      assertApproxEqual(col.red, Float(1.0))
      assertApproxEqual(col.green, Float(0.5))
      assertApproxEqual(col.blue, Float(0.25))
      assertApproxEqual(col.alpha, Float(0.8))
    } else {
      XCTFail("Modulate value should be Color")
    }
  }
}
