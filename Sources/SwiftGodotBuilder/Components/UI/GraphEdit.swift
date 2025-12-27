import Foundation
import SwiftGodot

// MARK: - Port Configuration

/// Configuration for a graph node port (input or output).
public struct Port {
  public let color: Color
  public let typeId: Int32

  /// Creates a port with a color and optional type for connection matching.
  /// Ports can only connect to other ports with the same type.
  /// - Parameters:
  ///   - color: The port color.
  ///   - type: A Swift type used for connection matching (e.g., `Float.self`, `String.self`).
  public init(_ color: Color = .white, type: Any.Type = Any.self) {
    self.color = color
    // Convert Swift type to stable Int32 for Godot
    typeId = Int32(truncatingIfNeeded: ObjectIdentifier(type).hashValue & 0x7FFF_FFFF)
  }
}

// MARK: - Slot Elements

/// An element that can appear as a slot in a GraphNode.
public protocol GraphNodeSlotElement {
  /// Adds this slot to the given GraphNode at the specified index.
  func addTo(_ graphNode: GraphNode, slotIndex: Int32)
}

/// A slot in a GraphNode with optional left/right ports.
public struct Slot: GraphNodeSlotElement {
  private let content: () -> Node
  let leftPort: Port?
  let rightPort: Port?

  /// Creates a slot with a text label.
  public init(
    _ label: String,
    left: Port? = nil,
    right: Port? = nil
  ) {
    content = {
      let labelNode = Label()
      labelNode.text = label
      return labelNode
    }
    leftPort = left
    rightPort = right
  }

  /// Creates a slot with GView content.
  public init<Content: GView>(
    left: Port? = nil,
    right: Port? = nil,
    content: () -> Content
  ) {
    let c = content()
    self.content = { c.toNode() }
    leftPort = left
    rightPort = right
  }

  public func addTo(_ graphNode: GraphNode, slotIndex: Int32) {
    graphNode.addChild(node: content())

    graphNode.setSlot(
      slotIndex: slotIndex,
      enableLeftPort: leftPort != nil,
      typeLeft: leftPort?.typeId ?? 0,
      colorLeft: leftPort?.color ?? .white,
      enableRightPort: rightPort != nil,
      typeRight: rightPort?.typeId ?? 0,
      colorRight: rightPort?.color ?? .white
    )
  }
}

// MARK: - SlotBuilder Result Builder

@resultBuilder
public struct SlotBuilder {
  public static func buildExpression(_ element: GraphNodeSlotElement) -> [GraphNodeSlotElement] {
    [element]
  }

  public static func buildBlock(_ components: [GraphNodeSlotElement]...) -> [GraphNodeSlotElement] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [GraphNodeSlotElement]?) -> [GraphNodeSlotElement] {
    component ?? []
  }

  public static func buildEither(first component: [GraphNodeSlotElement]) -> [GraphNodeSlotElement] {
    component
  }

  public static func buildEither(second component: [GraphNodeSlotElement]) -> [GraphNodeSlotElement] {
    component
  }

  public static func buildArray(_ components: [[GraphNodeSlotElement]]) -> [GraphNodeSlotElement] {
    components.flatMap { $0 }
  }
}

// MARK: - GNode<GraphNode> Extension

public extension GNode where T == GraphNode {
  /// Creates a GraphNode with declarative slots.
  ///
  /// ### Example
  /// ```swift
  /// GraphNode$(title: "Add") {
  ///     Slot("A", left: Port(.green, type: Float.self))
  ///     Slot("B", left: Port(.green, type: Float.self))
  ///     Slot(right: Port(.green, type: Float.self)) {
  ///         Label$().text("Result")
  ///     }
  /// }
  /// .positionOffset([100, 100])
  /// ```
  init(name: String = UUID().uuidString, title: String, @SlotBuilder slots: () -> [GraphNodeSlotElement]) {
    let slotElements = slots()
    self.init(name, make: {
      let node = GraphNode()
      node.title = title
      for (index, slot) in slotElements.enumerated() {
        slot.addTo(node, slotIndex: Int32(index))
      }
      return node
    })
  }

  /// Sets the position offset of the node in the graph.
  func positionOffset(_ offset: Vector2) -> Self {
    configure { node in
      node.positionOffset = offset
    }
  }
}
