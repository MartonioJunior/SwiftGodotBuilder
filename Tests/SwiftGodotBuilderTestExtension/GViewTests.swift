// GViewTests.swift
// Runtime tests for GView protocol and builders

import SwiftGodot
import SwiftGodotBuilder

// Simple test GView component
struct SimpleTestView: GView {
  var body: some GView {
    Node2D$().name("simpleViewRoot")
  }
}

// GView with children
struct ContainerTestView: GView {
  var body: some GView {
    Node2D$ {
      Sprite2D$().name("child1")
      Sprite2D$().name("child2")
      Sprite2D$().name("child3")
    }.name("container")
  }
}

// Nested GView
struct OuterTestView: GView {
  var body: some GView {
    Node2D$ {
      SimpleTestView()
    }.name("outer")
  }
}

struct GViewTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      test("testGViewToNode", testGViewToNode),
      test("testGViewWithChildren", testGViewWithChildren),
      test("testNestedGView", testNestedGView),
      test("testEmptyGView", testEmptyGView),
    ]
  }

  func testGViewToNode() {
    let view = SimpleTestView()
    let node = view.toNode()

    XCTAssertNotNil(node, "GView should produce a node")
    XCTAssertEqual(node.name.description, "simpleViewRoot", "Node should have correct name")
  }

  func testGViewWithChildren() {
    let view = ContainerTestView()
    let node = view.toNode()

    // The container is the root node returned by toNode()
    XCTAssertEqual(node.name.description, "container", "Container should be the root node")
    XCTAssertEqual(Int(node.getChildCount()), 3, "Container should have 3 children")
  }

  func testNestedGView() {
    let view = OuterTestView()
    let node = view.toNode()

    // Should find the outer container
    XCTAssertEqual(node.name.description, "outer", "Outer node should be root")

    // Should find the nested simple view's root
    let nested = node.findChild(pattern: "simpleViewRoot", recursive: true, owned: false)
    XCTAssertNotNil(nested, "Nested GView should be rendered")
  }

  func testEmptyGView() {
    let emptyView = EmptyGView()
    let node = emptyView.toNode()

    // EmptyGView produces an empty Node
    XCTAssertNotNil(node, "EmptyGView should still produce a node")
  }
}
