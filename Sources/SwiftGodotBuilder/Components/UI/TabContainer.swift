import Foundation
import SwiftGodot

// MARK: - Tab Elements

/// An element that can appear in a TabBar.
public protocol TabElement {
    /// Adds this element to the given TabBar.
    func addTo(_ tabBar: TabBar)
}

// MARK: - Tab

/// A tab for TabBar or TabContainer.
public struct Tab<Content: GView>: TabElement, GView {
    public let title: String
    public let icon: Texture2D?
    public let disabled: Bool
    public let content: Content?

    /// Creates a tab without content (for TabBar).
    public init(
        _ title: String,
        icon: Texture2D? = nil,
        disabled: Bool = false
    ) where Content == EmptyGView {
        self.title = title
        self.icon = icon
        self.disabled = disabled
        self.content = nil
    }

    /// Creates a tab with content (for TabContainer).
    public init(
        _ title: String,
        icon: Texture2D? = nil,
        disabled: Bool = false,
        content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.disabled = disabled
        self.content = content()
    }

    public func addTo(_ tabBar: TabBar) {
        let idx = tabBar.tabCount
        tabBar.addTab(title: title, icon: icon)
        if disabled {
            tabBar.setTabDisabled(tabIdx: idx, disabled: true)
        }
    }

    public func toNode() -> Node {
        let node = content?.toNode() ?? Control()
        node.name = StringName(title)
        return node
    }
}

// MARK: - TabBar Result Builder

@resultBuilder
public struct TabBuilder {
    public static func buildExpression(_ element: TabElement) -> [TabElement] {
        [element]
    }

    public static func buildBlock(_ components: [TabElement]...) -> [TabElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [TabElement]?) -> [TabElement] {
        component ?? []
    }

    public static func buildEither(first component: [TabElement]) -> [TabElement] {
        component
    }

    public static func buildEither(second component: [TabElement]) -> [TabElement] {
        component
    }

    public static func buildArray(_ components: [[TabElement]]) -> [TabElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<TabBar> Extension

public extension GNode where T == TabBar {
    /// Creates a TabBar with declarative tabs.
    init(_ name: String = UUID().uuidString, @TabBuilder content: () -> [TabElement]) {
        let elements = content()
        self.init(name, make: {
            let tabBar = TabBar()
            for element in elements {
                element.addTo(tabBar)
            }
            return tabBar
        })
    }

    /// Connects to the `tab_changed` signal.
    func onTabChanged(_ handler: @escaping (Int) -> Void) -> Self {
        configure { tabBar in
            tabBar.tabChanged.connect { index in
                handler(Int(index))
            }
        }
    }

    /// Connects to the `tab_selected` signal.
    func onTabSelected(_ handler: @escaping (Int) -> Void) -> Self {
        configure { tabBar in
            tabBar.tabSelected.connect { index in
                handler(Int(index))
            }
        }
    }
}

// MARK: - GNode<TabContainer> Extension

public extension GNode where T == TabContainer {
    /// Creates a TabContainer with Tab children.
    init(_ name: String = UUID().uuidString, @NodeBuilder content: () -> [any GView]) {
        let tabs = content()
        self.init(name, make: {
            let container = TabContainer()
            container.tabsVisible = true
            let nodes = tabs.map { $0.toNode() }
            Engine.onNextFrame {
                for node in nodes {
                    container.addChild(node: node)
                }
            }
            return container
        })
    }

    /// Connects to the `tab_changed` signal.
    func onTabChanged(_ handler: @escaping (Int) -> Void) -> Self {
        configure { container in
            container.tabChanged.connect { index in
                handler(Int(index))
            }
        }
    }

    /// Connects to the `tab_selected` signal.
    func onTabSelected(_ handler: @escaping (Int) -> Void) -> Self {
        configure { container in
            container.tabSelected.connect { index in
                handler(Int(index))
            }
        }
    }
}
