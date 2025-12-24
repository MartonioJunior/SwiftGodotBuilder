import Foundation
import SwiftGodot

// MARK: - Dialog Button Elements

/// An element that can be added to a dialog as a button.
public protocol DialogButtonElement {
    /// Adds this button to the given dialog.
    func addTo(_ dialog: AcceptDialog)
}

/// A custom button in a dialog.
public struct DialogButton: DialogButtonElement {
    public let text: String
    public let isRight: Bool
    public let action: String

    /// Creates a dialog button.
    /// - Parameters:
    ///   - text: The button label.
    ///   - right: If true, places button on the right side.
    ///   - action: Custom action name emitted when clicked.
    public init(_ text: String, right: Bool = true, action: String = "") {
        self.text = text
        isRight = right
        self.action = action
    }

    public func addTo(_ dialog: AcceptDialog) {
        _ = dialog.addButton(text: text, right: isRight, action: action)
    }
}

/// A cancel button that hides the dialog.
public struct CancelButton: DialogButtonElement {
    public let text: String

    public init(_ text: String = "Cancel") {
        self.text = text
    }

    public func addTo(_ dialog: AcceptDialog) {
        _ = dialog.addCancelButton(name: text)
    }
}

// MARK: - DialogButton Result Builder

@resultBuilder
public struct DialogButtonBuilder {
    public static func buildExpression(_ element: DialogButtonElement) -> [DialogButtonElement] {
        [element]
    }

    public static func buildBlock(_ components: [DialogButtonElement]...) -> [DialogButtonElement] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [DialogButtonElement]?) -> [DialogButtonElement] {
        component ?? []
    }

    public static func buildEither(first component: [DialogButtonElement]) -> [DialogButtonElement] {
        component
    }

    public static func buildEither(second component: [DialogButtonElement]) -> [DialogButtonElement] {
        component
    }

    public static func buildArray(_ components: [[DialogButtonElement]]) -> [DialogButtonElement] {
        components.flatMap { $0 }
    }
}

// MARK: - GNode<AcceptDialog> Extension

public extension GNode where T == AcceptDialog {
    /// Creates an AcceptDialog with declarative buttons.
    ///
    /// ### Example
    /// ```swift
    /// AcceptDialog$ {
    ///     DialogButton("Save", action: "save")
    ///     DialogButton("Don't Save", action: "discard")
    ///     CancelButton()
    /// }
    /// .title("Unsaved Changes")
    /// .dialogText("Do you want to save your changes?")
    /// .onConfirmed { print("OK pressed") }
    /// .onCustomAction { action in
    ///     switch action {
    ///     case "save": saveDocument()
    ///     case "discard": discardChanges()
    ///     default: break
    ///     }
    /// }
    /// ```
    init(_ name: String = UUID().uuidString, @DialogButtonBuilder buttons: () -> [DialogButtonElement]) {
        let elements = buttons()
        self.init(name, make: {
            let dialog = AcceptDialog()
            for element in elements {
                element.addTo(dialog)
            }
            return dialog
        })
    }

    /// Sets the dialog title.
    func title(_ title: String) -> Self {
        configure { dialog in
            dialog.title = title
        }
    }

    /// Sets the dialog text content.
    func dialogText(_ text: String) -> Self {
        configure { dialog in
            dialog.dialogText = text
        }
    }

    /// Sets the OK button text.
    func okButtonText(_ text: String) -> Self {
        configure { dialog in
            dialog.okButtonText = text
        }
    }

    /// Connects to the `confirmed` signal (OK button pressed).
    func onConfirmed(_ handler: @escaping () -> Void) -> Self {
        configure { dialog in
            dialog.confirmed.connect {
                handler()
            }
        }
    }

    /// Connects to the `canceled` signal.
    func onCanceled(_ handler: @escaping () -> Void) -> Self {
        configure { dialog in
            dialog.canceled.connect {
                handler()
            }
        }
    }

    /// Connects to the `custom_action` signal for custom buttons.
    func onCustomAction(_ handler: @escaping (String) -> Void) -> Self {
        configure { dialog in
            dialog.customAction.connect { action in
                handler(String(action))
            }
        }
    }
}

// MARK: - GNode<FileDialog> Extension

public extension GNode where T == FileDialog {
    /// Connects to the `file_selected` signal.
    func onFileSelected(_ handler: @escaping (String) -> Void) -> Self {
        configure { dialog in
            dialog.fileSelected.connect { path in
                handler(path)
            }
        }
    }

    /// Connects to the `files_selected` signal (multi-select mode).
    func onFilesSelected(_ handler: @escaping (PackedStringArray) -> Void) -> Self {
        configure { dialog in
            dialog.filesSelected.connect { paths in
                handler(paths)
            }
        }
    }

    /// Connects to the `dir_selected` signal.
    func onDirSelected(_ handler: @escaping (String) -> Void) -> Self {
        configure { dialog in
            dialog.dirSelected.connect { path in
                handler(path)
            }
        }
    }

    /// Adds a file filter.
    func filter(_ description: String, _ extensions: String) -> Self {
        configure { dialog in
            dialog.addFilter(extensions, description: description)
        }
    }
}
