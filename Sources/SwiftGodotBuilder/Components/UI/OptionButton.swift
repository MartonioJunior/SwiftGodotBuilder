import Foundation
import SwiftGodot

// MARK: - OptionButton Elements

/// An element that can appear in an OptionButton.
public protocol OptionElement {
    /// Adds this element to the given OptionButton.
    func addTo(_ button: OptionButton, idCounter: inout Int32)
}

/// An option item in a dropdown.
public struct Option: OptionElement {
    public let text: String
    public let icon: Texture2D?
    public let id: Int32?
    public let disabled: Bool

    public init(
        _ text: String,
        icon: Texture2D? = nil,
        id: Int32? = nil,
        disabled: Bool = false
    ) {
        self.text = text
        self.icon = icon
        self.id = id
        self.disabled = disabled
    }

    public func addTo(_ button: OptionButton, idCounter: inout Int32) {
        let itemId = id ?? idCounter
        if id == nil { idCounter += 1 }

        if let icon {
            button.addIconItem(texture: icon, label: text, id: itemId)
        } else {
            button.addItem(label: text, id: itemId)
        }

        if disabled {
            let idx = button.getItemIndex(id: itemId)
            button.setItemDisabled(idx: idx, disabled: true)
        }
    }
}

/// A separator in the dropdown.
public struct OptionSeparator: OptionElement {
    public init() {}

    public func addTo(_ button: OptionButton, idCounter _: inout Int32) {
        button.addSeparator()
    }
}

// MARK: - OptionButton Result Builder

@resultBuilder
public struct OptionBuilder {
    public static func buildExpression(_ element: OptionElement) -> [OptionElement] {
        [element]
    }

    public static func buildBlock(_ components: [OptionElement]...) -> [OptionElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [OptionElement]?) -> [OptionElement] {
        component ?? []
    }

    public static func buildEither(first component: [OptionElement]) -> [OptionElement] {
        component
    }

    public static func buildEither(second component: [OptionElement]) -> [OptionElement] {
        component
    }

    public static func buildArray(_ components: [[OptionElement]]) -> [OptionElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<OptionButton> Extension

public extension GNode where T == OptionButton {
    /// Creates an OptionButton with declarative options.
    ///
    /// ### Example
    /// ```swift
    /// OptionButton$ {
    ///     Option("Small", id: 0)
    ///     Option("Medium", id: 1)
    ///     Option("Large", id: 2)
    ///     OptionSeparator()
    ///     Option("Custom...", id: 99)
    /// }
    /// .onItemSelected { id in
    ///     print("Selected: \(id)")
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @OptionBuilder content: () -> [OptionElement]) {
        let elements = content()
        self.init(name, make: {
            let button = OptionButton()
            var idCounter: Int32 = 0
            for element in elements {
                element.addTo(button, idCounter: &idCounter)
            }
            return button
        })
    }

    /// Connects to the `item_selected` signal.
    func onItemSelected(_ handler: @escaping (Int) -> Void) -> Self {
        configure { button in
            button.itemSelected.connect { index in
                handler(Int(index))
            }
        }
    }
}
