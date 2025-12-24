import Foundation
import SwiftGodot

// MARK: - Menu Elements

/// An element that can appear in a PopupMenu.
public protocol MenuElement {
    /// Adds this element to the given PopupMenu.
    func addTo(_ menu: PopupMenu, idCounter: inout Int32)
}

/// A clickable menu item.
public struct MenuItem: MenuElement {
    public let text: String
    public let icon: Texture2D?
    public let shortcut: Shortcut?
    public let disabled: Bool
    public let id: Int32?

    public init(
        _ text: String,
        icon: Texture2D? = nil,
        shortcut: Shortcut? = nil,
        disabled: Bool = false,
        id: Int32? = nil
    ) {
        self.text = text
        self.icon = icon
        self.shortcut = shortcut
        self.disabled = disabled
        self.id = id
    }

    public func addTo(_ menu: PopupMenu, idCounter: inout Int32) {
        let itemId = id ?? idCounter
        if id == nil { idCounter += 1 }

        if let icon {
            menu.addIconItem(texture: icon, label: text, id: itemId)
        } else {
            menu.addItem(label: text, id: itemId)
        }

        if let shortcut {
            let idx = menu.getItemIndex(id: itemId)
            menu.setItemShortcut(index: idx, shortcut: shortcut)
        }

        if disabled {
            let idx = menu.getItemIndex(id: itemId)
            menu.setItemDisabled(index: idx, disabled: true)
        }
    }
}

/// A checkbox menu item.
public struct MenuCheckItem: MenuElement {
    public let text: String
    public let checked: Bool
    public let id: Int32?

    public init(_ text: String, checked: Bool = false, id: Int32? = nil) {
        self.text = text
        self.checked = checked
        self.id = id
    }

    public func addTo(_ menu: PopupMenu, idCounter: inout Int32) {
        let itemId = id ?? idCounter
        if id == nil { idCounter += 1 }

        menu.addCheckItem(label: text, id: itemId)
        if checked {
            let idx = menu.getItemIndex(id: itemId)
            menu.setItemChecked(index: idx, checked: true)
        }
    }
}

/// A radio button menu item.
public struct MenuRadioItem: MenuElement {
    public let text: String
    public let checked: Bool
    public let id: Int32?

    public init(_ text: String, checked: Bool = false, id: Int32? = nil) {
        self.text = text
        self.checked = checked
        self.id = id
    }

    public func addTo(_ menu: PopupMenu, idCounter: inout Int32) {
        let itemId = id ?? idCounter
        if id == nil { idCounter += 1 }

        menu.addRadioCheckItem(label: text, id: itemId)
        if checked {
            let idx = menu.getItemIndex(id: itemId)
            menu.setItemChecked(index: idx, checked: true)
        }
    }
}

/// A visual separator between menu items.
public struct MenuSeparator: MenuElement {
    public let label: String?

    public init(_ label: String? = nil) {
        self.label = label
    }

    public func addTo(_ menu: PopupMenu, idCounter _: inout Int32) {
        menu.addSeparator(label: label ?? "")
    }
}

/// A submenu containing nested menu items.
public struct SubMenu: MenuElement {
    public let text: String
    public let elements: [MenuElement]

    public init(_ text: String, @MenuBuilder content: () -> [MenuElement]) {
        self.text = text
        elements = content()
    }

    public func addTo(_ menu: PopupMenu, idCounter: inout Int32) {
        let submenu = PopupMenu()
        submenu.name = StringName(text.replacingOccurrences(of: " ", with: "_"))

        for element in elements {
            element.addTo(submenu, idCounter: &idCounter)
        }

        menu.addChild(node: submenu)
        menu.addSubmenuItem(label: text, submenu: String(submenu.name))
    }
}

// MARK: - Result Builder

/// Result builder for composing menu elements.
@resultBuilder
public struct MenuBuilder {
    public static func buildExpression(_ element: MenuElement) -> [MenuElement] {
        [element]
    }

    public static func buildBlock(_ components: [MenuElement]...) -> [MenuElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [MenuElement]?) -> [MenuElement] {
        component ?? []
    }

    public static func buildEither(first component: [MenuElement]) -> [MenuElement] {
        component
    }

    public static func buildEither(second component: [MenuElement]) -> [MenuElement] {
        component
    }

    public static func buildArray(_ components: [[MenuElement]]) -> [MenuElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<Control> Extension

public extension GNode where T: Control {
    /// Adds a context menu that appears on right-click.
    ///
    /// ### Example
    /// ```swift
    /// Label$().text("Hello")
    ///     .contextMenu {
    ///         MenuItem("Option 1")
    ///         MenuItem("Option 2")
    ///     } onItemPressed: { id in
    ///         print("Selected: \(id)")
    ///     }
    /// ```
    func contextMenu(
        @MenuBuilder menu menuBuilder: @escaping () -> [MenuElement],
        onItemPressed handler: @escaping (Int) -> Void
    ) -> Self {
        configure { control in
            control.mouseFilter = .stop

            let menu = PopupMenu()
            var idCounter: Int32 = 0
            for element in menuBuilder() {
                element.addTo(menu, idCounter: &idCounter)
            }
            control.addChild(node: menu)

            menu.idPressed.connect { id in
                handler(Int(id))
            }

            control.guiInput.connect { event in
                guard let mouseEvent = event as? InputEventMouseButton else { return }
                guard mouseEvent.buttonIndex == .right && mouseEvent.pressed else { return }
                let gp = mouseEvent.globalPosition
                menu.position = Vector2i(x: Int32(gp.x), y: Int32(gp.y))
                menu.popup()
            }
        }
    }
}
