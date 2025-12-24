import Foundation
import SwiftGodot

// MARK: - Tab Elements

/// An element that can appear in a TabBar.
public protocol TabElement {
    /// Adds this element to the given TabBar.
    func addTo(_ tabBar: TabBar)
}

/// A tab in a TabBar.
public struct Tab: TabElement {
    public let title: String
    public let icon: Texture2D?
    public let disabled: Bool

    public init(
        _ title: String,
        icon: Texture2D? = nil,
        disabled: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.disabled = disabled
    }

    public func addTo(_ tabBar: TabBar) {
        let idx = tabBar.tabCount
        tabBar.addTab(title: title, icon: icon)
        if disabled {
            tabBar.setTabDisabled(tabIdx: idx, disabled: true)
        }
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
    ///
    /// ### Example
    /// ```swift
    /// TabBar$ {
    ///     Tab("General")
    ///     Tab("Audio")
    ///     Tab("Video")
    ///     Tab("Advanced", disabled: true)
    /// }
    /// .onTabChanged { index in
    ///     print("Tab: \(index)")
    /// }
    /// ```
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

// MARK: - TabContainer Content

/// A tab with content for TabContainer.
public struct TabContent<Content: GView>: GView {
    public let title: String
    public let content: Content

    public init(_ title: String, content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public func toNode() -> Node {
        let node = content.toNode()
        node.name = StringName(title)
        return node
    }
}

// MARK: - GNode<TabContainer> Extension

public extension GNode where T == TabContainer {
    /// Creates a TabContainer with TabContent children.
    ///
    /// ### Example
    /// ```swift
    /// TabContainer$ {
    ///     TabContent("General") { Label$().text("General settings") }
    ///     TabContent("Audio") { Label$().text("Audio settings") }
    /// }
    /// .onTabChanged { index in ... }
    /// ```
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
