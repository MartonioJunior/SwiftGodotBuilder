import Foundation
import SwiftGodot

// MARK: - RichText Elements

/// An element that can appear in a RichTextLabel.
public protocol RichTextElement {
    /// Adds this element to the given RichTextLabel.
    func addTo(_ label: RichTextLabel)
}

/// Plain text content.
public struct Text: RichTextElement {
    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public func addTo(_ label: RichTextLabel) {
        label.appendText(bbcode: content)
    }
}

/// Bold text.
public struct Bold: RichTextElement {
    public let children: [RichTextElement]

    public init(_ text: String) {
        children = [Text(text)]
    }

    public init(@RichTextBuilder content: () -> [RichTextElement]) {
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushBold()
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// Italic text.
public struct Italic: RichTextElement {
    public let children: [RichTextElement]

    public init(_ text: String) {
        children = [Text(text)]
    }

    public init(@RichTextBuilder content: () -> [RichTextElement]) {
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushItalics()
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// Underlined text.
public struct Underline: RichTextElement {
    public let children: [RichTextElement]

    public init(_ text: String) {
        children = [Text(text)]
    }

    public init(@RichTextBuilder content: () -> [RichTextElement]) {
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushUnderline()
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// Strikethrough text.
public struct Strikethrough: RichTextElement {
    public let children: [RichTextElement]

    public init(_ text: String) {
        children = [Text(text)]
    }

    public init(@RichTextBuilder content: () -> [RichTextElement]) {
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushStrikethrough()
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// Colored text.
public struct Colored: RichTextElement {
    public let color: Color
    public let children: [RichTextElement]

    public init(_ color: Color, _ text: String) {
        self.color = color
        children = [Text(text)]
    }

    public init(_ color: Color, @RichTextBuilder content: () -> [RichTextElement]) {
        self.color = color
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushColor(color)
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// Text with custom font size.
public struct FontSize: RichTextElement {
    public let size: Int32
    public let children: [RichTextElement]

    public init(_ size: Int32, _ text: String) {
        self.size = size
        children = [Text(text)]
    }

    public init(_ size: Int32, @RichTextBuilder content: () -> [RichTextElement]) {
        self.size = size
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushFontSize(size)
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// A clickable link. Use `onMetaClicked` on the RichTextLabel to handle clicks.
public struct Link: RichTextElement {
    public let meta: Variant
    public let children: [RichTextElement]

    public init(_ url: String, _ text: String) {
        meta = Variant(url)
        children = [Text(text)]
    }

    public init(_ meta: Variant, @RichTextBuilder content: () -> [RichTextElement]) {
        self.meta = meta
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        label.pushMeta(data: meta)
        for child in children {
            child.addTo(label)
        }
        label.pop()
    }
}

/// A newline.
public struct Newline: RichTextElement {
    public init() {}

    public func addTo(_ label: RichTextLabel) {
        label.appendText(bbcode: "\n")
    }
}

/// A paragraph break (double newline).
public struct Paragraph: RichTextElement {
    public let children: [RichTextElement]

    public init(@RichTextBuilder content: () -> [RichTextElement]) {
        children = content()
    }

    public func addTo(_ label: RichTextLabel) {
        for child in children {
            child.addTo(label)
        }
        label.appendText(bbcode: "\n\n")
    }
}

// MARK: - RichText Result Builder

@resultBuilder
public struct RichTextBuilder {
    public static func buildExpression(_ element: RichTextElement) -> [RichTextElement] {
        [element]
    }

    public static func buildExpression(_ text: String) -> [RichTextElement] {
        [Text(text)]
    }

    public static func buildBlock(_ components: [RichTextElement]...) -> [RichTextElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [RichTextElement]?) -> [RichTextElement] {
        component ?? []
    }

    public static func buildEither(first component: [RichTextElement]) -> [RichTextElement] {
        component
    }

    public static func buildEither(second component: [RichTextElement]) -> [RichTextElement] {
        component
    }

    public static func buildArray(_ components: [[RichTextElement]]) -> [RichTextElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<RichTextLabel> Extension

public extension GNode where T == RichTextLabel {
    /// Creates a RichTextLabel with declarative formatted content.
    ///
    /// ### Example
    /// ```swift
    /// RichTextLabel$ {
    ///     Bold("Important: ")
    ///     "Normal text "
    ///     Colored(.red, "Warning!")
    ///     Newline()
    ///     Italic {
    ///         "This is "
    ///         Bold("bold and italic")
    ///     }
    /// }
    /// .onMetaClicked { meta in
    ///     print("Clicked: \(meta)")
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @RichTextBuilder content: () -> [RichTextElement]) {
        let elements = content()
        self.init(name, make: {
            let label = RichTextLabel()
            label.bbcodeEnabled = false
            for element in elements {
                element.addTo(label)
            }
            return label
        })
    }
}
