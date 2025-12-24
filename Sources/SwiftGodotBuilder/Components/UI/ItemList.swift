import Foundation
import SwiftGodot

// MARK: - ItemList Elements

/// An element that can appear in an ItemList.
public protocol ItemListElement {
    /// Adds this element to the given ItemList.
    func addTo(_ list: ItemList)
}

/// A list item with text and optional icon.
public struct ListItem: ItemListElement {
    public let text: String
    public let icon: Texture2D?
    public let selectable: Bool
    public let disabled: Bool

    public init(
        _ text: String,
        icon: Texture2D? = nil,
        selectable: Bool = true,
        disabled: Bool = false
    ) {
        self.text = text
        self.icon = icon
        self.selectable = selectable
        self.disabled = disabled
    }

    public func addTo(_ list: ItemList) {
        let idx = list.addItem(text: text, icon: icon, selectable: selectable)
        if disabled {
            list.setItemDisabled(idx: idx, disabled: true)
        }
    }
}

/// An icon-only list item.
public struct ListIcon: ItemListElement {
    public let icon: Texture2D
    public let selectable: Bool

    public init(_ icon: Texture2D, selectable: Bool = true) {
        self.icon = icon
        self.selectable = selectable
    }

    public func addTo(_ list: ItemList) {
        _ = list.addIconItem(icon: icon, selectable: selectable)
    }
}

// MARK: - ItemList Result Builder

@resultBuilder
public struct ItemListBuilder {
    public static func buildExpression(_ element: ItemListElement) -> [ItemListElement] {
        [element]
    }

    public static func buildBlock(_ components: [ItemListElement]...) -> [ItemListElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [ItemListElement]?) -> [ItemListElement] {
        component ?? []
    }

    public static func buildEither(first component: [ItemListElement]) -> [ItemListElement] {
        component
    }

    public static func buildEither(second component: [ItemListElement]) -> [ItemListElement] {
        component
    }

    public static func buildArray(_ components: [[ItemListElement]]) -> [ItemListElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<ItemList> Extension

public extension GNode where T == ItemList {
    /// Creates an ItemList with declarative items.
    ///
    /// ### Example
    /// ```swift
    /// ItemList$ {
    ///     ListItem("Apple")
    ///     ListItem("Banana")
    ///     ListItem("Cherry", disabled: true)
    /// }
    /// .onItemSelected { index in
    ///     print("Selected: \(index)")
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @ItemListBuilder content: () -> [ItemListElement]) {
        let elements = content()
        self.init(name, make: {
            let list = ItemList()
            for element in elements {
                element.addTo(list)
            }
            return list
        })
    }

    /// Connects to the `item_selected` signal.
    func onItemSelected(_ handler: @escaping (Int) -> Void) -> Self {
        configure { list in
            list.itemSelected.connect { index in
                handler(Int(index))
            }
        }
    }

    /// Connects to the `item_activated` signal (double-click).
    func onItemActivated(_ handler: @escaping (Int) -> Void) -> Self {
        configure { list in
            list.itemActivated.connect { index in
                handler(Int(index))
            }
        }
    }
}
