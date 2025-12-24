import Foundation
import SwiftGodot

// MARK: - Tree Elements

/// An element that can appear in a Tree.
public protocol TreeElement {
    /// Adds this element to the given Tree under the specified parent.
    func addTo(_ tree: Tree, parent: TreeItem?, column: Int32)
}

/// A tree item with optional children.
public struct TreeNode: TreeElement {
    public let text: String
    public let icon: Texture2D?
    public let selectable: Bool
    public let editable: Bool
    public let children: [TreeElement]

    public init(
        _ text: String,
        icon: Texture2D? = nil,
        selectable: Bool = true,
        editable: Bool = false,
        @TreeBuilder children: () -> [TreeElement] = { [] }
    ) {
        self.text = text
        self.icon = icon
        self.selectable = selectable
        self.editable = editable
        self.children = children()
    }

    public func addTo(_ tree: Tree, parent: TreeItem?, column: Int32) {
        let item = tree.createItem(parent: parent)
        item?.setText(column: column, text: text)

        if let icon {
            item?.setIcon(column: column, texture: icon)
        }

        item?.setSelectable(column: column, selectable: selectable)
        item?.setEditable(column: column, enabled: editable)

        for child in children {
            child.addTo(tree, parent: item, column: column)
        }
    }
}

// MARK: - Tree Result Builder

@resultBuilder
public struct TreeBuilder {
    public static func buildExpression(_ element: TreeElement) -> [TreeElement] {
        [element]
    }

    public static func buildBlock(_ components: [TreeElement]...) -> [TreeElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [TreeElement]?) -> [TreeElement] {
        component ?? []
    }

    public static func buildEither(first component: [TreeElement]) -> [TreeElement] {
        component
    }

    public static func buildEither(second component: [TreeElement]) -> [TreeElement] {
        component
    }

    public static func buildArray(_ components: [[TreeElement]]) -> [TreeElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<Tree> Extension

public extension GNode where T == Tree {
    /// Creates a Tree with declarative items.
    ///
    /// ### Example
    /// ```swift
    /// Tree$ {
    ///     TreeNode("Root") {
    ///         TreeNode("Child 1")
    ///         TreeNode("Child 2") {
    ///             TreeNode("Grandchild")
    ///         }
    ///     }
    /// }
    /// .onItemSelected {
    ///     print("Item selected")
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @TreeBuilder content: () -> [TreeElement]) {
        let elements = content()
        self.init(name, make: {
            let tree = Tree()
            for element in elements {
                element.addTo(tree, parent: nil, column: 0)
            }
            return tree
        })
    }

    /// Connects to the `item_selected` signal.
    func onItemSelected(_ handler: @escaping () -> Void) -> Self {
        configure { tree in
            tree.itemSelected.connect {
                handler()
            }
        }
    }

    /// Connects to the `item_activated` signal (double-click).
    func onItemActivated(_ handler: @escaping () -> Void) -> Self {
        configure { tree in
            tree.itemActivated.connect {
                handler()
            }
        }
    }
}
