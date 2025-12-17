//
//  GView.swift
//
//  Created by John Susek on 08/26/2025.
//

import SwiftGodot

/// A SwiftUI-inspired protocol for declaratively describing
/// Godot node hierarchies in Swift.
///
/// Conformers model *views* that ultimately materialize into a Godot
/// `Node` via ``toNode()``. Composition works similarly to SwiftUI:
/// a view either renders itself (a *leaf* view) or defers rendering to
/// its ``body`` (a *composite* view).
@_documentation(visibility: private)
public protocol GView {
  /// The declarative content of this view.
  ///
  /// Defaults to `NeverGView` for leaf views. If you provide a concrete
  /// `Body`, the default ``toNode()`` will delegate to `body.toNode()`.
  associatedtype Body: GView = NeverGView

  /// The view's body, used for composition.
  ///
  /// For leaf views (where `Body == NeverGView`) this property is provided
  /// by the protocol extension and traps if accessed.
  var body: Body { get }

  /// Materializes this view into a concrete Godot `Node`.
  ///
  /// - Returns: A fully constructed `Node` ready to be inserted in the tree.
  func toNode() -> Node

  /// Indicates whether this view's children should be flattened into the parent.
  ///
  /// When true, instead of adding this view's node as a child, the parent
  /// will call `toNodeWithParent()` passing itself as the parent.
  var shouldFlattenChildren: Bool { get }

  /// Materializes this view with a reference to its parent node.
  ///
  /// Only called when `shouldFlattenChildren` is true. The view can then
  /// add its children directly to the parent.
  func toNodeWithParent(_ parent: Node) -> Node?
}

public extension GView {
  /// Default implementation that delegates rendering to ``body``.
  ///
  /// Composite views typically rely on this; leaf views override it.
  ///
  /// - Returns: The node produced by `body.toNode()`.
  func toNode() -> Node { body.toNode() }

  /// Default implementation - views don't flatten by default.
  var shouldFlattenChildren: Bool { false }

  /// Default implementation - returns nil (node not used).
  func toNodeWithParent(_: Node) -> Node? { nil }
}

@_documentation(visibility: private)
public extension GView where Body == NeverGView {
  /// Default `body` for leaf views.
  var body: NeverGView { NeverGView() }
}

/// A view used as the default `Body` for leaf `GView`s.
@_documentation(visibility: private)
public struct NeverGView: GView {
  /// Traps unconditionally - `NeverGView` should never be rendered.
  public func toNode() -> Node {
    GD.printErr("NeverGView should never render. Did you write `any GView` instead of `some GView`?")
    return Node()
  }
}

/// An empty view that renders nothing.
/// Used as the default type for optional content in generic GViews.
public struct EmptyGView: GView {
  public init() {}
  public func toNode() -> Node { Node() }
}

/// A result builder for composing GView content in custom components.
///
/// Works with both single and multiple children:
/// ```swift
/// // Single child - returns it directly
/// struct Wrapper<Content: GView>: GView {
///   let content: Content
///   init(@GViewBuilder content: () -> Content) {
///     self.content = content()
///   }
/// }
///
/// // Multiple children - wraps in GViewGroup
/// Wrapper {
///   Label$().text("One")
///   Label$().text("Two")
/// }
/// ```
@resultBuilder
public enum GViewBuilder {
  public static func buildBlock<V: GView>(_ v: V) -> V { v }

  public static func buildBlock(_ views: any GView...) -> GViewGroup {
    GViewGroup(views: views)
  }

  public static func buildOptional<V: GView>(_ v: V?) -> any GView {
    v ?? GViewGroup(views: [])
  }

  public static func buildEither<V: GView>(first: V) -> V { first }
  public static func buildEither<V: GView>(second: V) -> V { second }
}

/// A group of views that flattens its children into the parent node.
public struct GViewGroup: GView {
  public let views: [any GView]

  public var shouldFlattenChildren: Bool { true }

  public func toNode() -> Node {
    // Shouldn't be called directly - parent should use toNodeWithParent
    let container = Node()
    for view in views {
      container.addChild(node: view.toNode())
    }
    return container
  }

  public func toNodeWithParent(_ parent: Node) -> Node? {
    for view in views {
      if view.shouldFlattenChildren {
        _ = view.toNodeWithParent(parent)
      } else {
        parent.addChild(node: view.toNode())
      }
    }
    return nil
  }
}

/// A result builder that collects `GView` children for container nodes.
@_documentation(visibility: private)
@resultBuilder
public enum NodeBuilder {
  /// Combines multiple child lists into a single flattened list.
  ///
  /// - Parameter c: Variadic groups of children.
  /// - Returns: A single flattened array of children.
  public static func buildBlock(_ c: [any GView]...) -> [any GView] { c.flatMap { $0 } }

  /// Flattens an array of child lists produced by loops/maps.
  ///
  /// - Parameter c: An array of child arrays.
  /// - Returns: A single flattened array of children.
  public static func buildArray(_ c: [[any GView]]) -> [any GView] { c.flatMap { $0 } }

  /// Passes through children when present, or yields an empty list.
  ///
  /// - Parameter c: Optional children.
  /// - Returns: `c` or `[]` if `nil`.
  public static func buildOptional(_ c: [any GView]?) -> [any GView] { c ?? [] }

  /// Chooses the `first` branch in `if/else` compositions.
  ///
  /// - Parameter first: Children from the first branch.
  /// - Returns: The provided children.
  public static func buildEither(first: [any GView]) -> [any GView] { first }

  /// Chooses the `second` branch in `if/else` compositions.
  ///
  /// - Parameter second: Children from the second branch.
  /// - Returns: The provided children.
  public static func buildEither(second: [any GView]) -> [any GView] { second }

  /// Lifts a single `GView` into a child list.
  ///
  /// - Parameter v: A child view.
  /// - Returns: A single-element child array.
  public static func buildExpression(_ v: any GView) -> [any GView] { [v] }

  /// Passes through an already-built child list (useful for `map`/loops).
  ///
  /// - Parameter v: A list of child views.
  /// - Returns: The same list.
  public static func buildExpression(_ v: [any GView]) -> [any GView] { v }
}

// MARK: - GView Ref Extension

public extension GView {
  /// Captures a reference to the root node produced by this GView.
  ///
  /// ### Usage:
  /// ```swift
  /// @State var cameraNode: Camera2D?
  ///
  /// CameraView()
  ///   .ref($cameraNode)
  /// ```
  ///
  /// The reference is set when the node is created via `toNode()`.
  func ref<N: Node>(_ binding: GState<N?>) -> some GView {
    GViewWithRef(content: self, binding: binding)
  }
}

/// A wrapper view that captures a reference to its content's root node.
public struct GViewWithRef<Content: GView, N: Node>: GView {
  let content: Content
  let binding: GState<N?>

  public func toNode() -> Node {
    let node = content.toNode()
    binding.wrappedValue = node as? N
    return node
  }
}

// MARK: - GView Typed Modifier Extension

public extension GView {
  /// Casts this GView to enable root node property modifiers.
  ///
  /// Use this when you need to set properties on a GView's root node:
  /// ```swift
  /// NewActorView { ... }
  ///   .as(CharacterBody2D.self)
  ///   .position(entity.position)
  ///   .visible(true)
  /// ```
  ///
  /// The returned `ModifiedGView` supports `@dynamicMemberLookup`, so any
  /// writable property on the root node type can be set as a modifier.
  func `as`<T: Node>(_: T.Type) -> ModifiedGView<Self, T> {
    ModifiedGView(content: self)
  }
}

/// A wrapper that applies property modifiers to a GView's root node.
///
/// Created via `.as(NodeType.self)` on any GView. Supports `@dynamicMemberLookup`
/// for fluent property assignment:
/// ```swift
/// MyCustomView()
///   .as(Node2D.self)
///   .position([100, 200])
///   .scale([2, 2])
///   .rotation(0.5)
/// ```
@dynamicMemberLookup
public struct ModifiedGView<Content: GView, RootType: Node>: GView {
  let content: Content
  var ops: [(RootType) -> Void] = []

  init(content: Content, ops: [(RootType) -> Void] = []) {
    self.content = content
    self.ops = ops
  }

  public func toNode() -> Node {
    let node = content.toNode()
    if let root = node as? RootType {
      ops.forEach { $0(root) }
    }
    return node
  }

  /// Dynamic-member setter for any writable property on the root node type.
  public subscript<V>(dynamicMember kp: ReferenceWritableKeyPath<RootType, V>) -> (V) -> Self {
    { v in
      var s = self
      s.ops.append { $0[keyPath: kp] = v }
      return s
    }
  }

  /// Dynamic-member convenience for `StringName` properties.
  public subscript(dynamicMember kp: ReferenceWritableKeyPath<RootType, StringName>) -> (String) -> Self {
    { s in
      var copy = self
      copy.ops.append { $0[keyPath: kp] = StringName(s) }
      return copy
    }
  }
}
