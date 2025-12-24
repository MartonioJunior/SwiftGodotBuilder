import Foundation
import SwiftGodot

// MARK: - MenuBar Elements

/// A menu in a MenuBar.
public struct Menu: GView {
    public let title: String
    public let elements: [MenuElement]
    var onItemPressed: ((Int) -> Void)?

    public init(_ title: String, @MenuBuilder content: () -> [MenuElement]) {
        self.title = title
        elements = content()
    }

    public func toNode() -> Node {
        let menu = PopupMenu()
        menu.name = StringName(title)

        var idCounter: Int32 = 0
        for element in elements {
            element.addTo(menu, idCounter: &idCounter)
        }

        if let handler = onItemPressed {
            menu.idPressed.connect { id in
                handler(Int(id))
            }
        }

        return menu
    }

    /// Handles menu item selection.
    public func onItemPressed(_ handler: @escaping (Int) -> Void) -> Self {
        var copy = self
        copy.onItemPressed = handler
        return copy
    }
}

// MARK: - GNode<MenuBar> Extension

public extension GNode where T == MenuBar {
    /// Creates a MenuBar with declarative menus.
    ///
    /// ### Example
    /// ```swift
    /// MenuBar$ {
    ///     Menu("File") {
    ///         MenuItem("New", id: 0)
    ///         MenuItem("Open...", id: 1)
    ///         MenuSeparator()
    ///         MenuItem("Quit", id: 99)
    ///     }
    ///     .onItemPressed { id in
    ///         handleFileMenu(id)
    ///     }
    ///
    ///     Menu("Edit") {
    ///         MenuItem("Undo", id: 0)
    ///         MenuItem("Redo", id: 1)
    ///         MenuSeparator()
    ///         MenuItem("Cut", id: 10)
    ///         MenuItem("Copy", id: 11)
    ///         MenuItem("Paste", id: 12)
    ///     }
    ///     .onItemPressed { id in
    ///         handleEditMenu(id)
    ///     }
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @NodeBuilder content: () -> [any GView]) {
        let menus = content()
        self.init(name, make: {
            let menuBar = MenuBar()
            for menu in menus {
                menuBar.addChild(node: menu.toNode())
            }
            return menuBar
        })
    }
}
