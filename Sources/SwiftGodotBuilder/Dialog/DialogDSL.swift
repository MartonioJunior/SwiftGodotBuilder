import Foundation
import SwiftGodot

// MARK: - Core Types

/// A character who speaks dialog lines.
///
/// ### Example
/// ```swift
/// let Guard = Speaker("Guard")
/// let dialog = Dialog {
///   Branch("intro") {
///     Guard ~ "Halt! Who goes there?"
///   }
/// }
/// ```
public struct Speaker: Sendable {
  public let name: String

  public init(_ name: String) {
    self.name = name
  }
}

/// Infix operator for dialog lines: `Speaker ~ "text"`
infix operator ~: AdditionPrecedence

public func ~ (speaker: Speaker, text: String) -> DialogElement {
  .line(speaker: speaker.name, text: text)
}

/// Create a choice option.
///
/// ### Example
/// ```swift
/// Choice("Pay 10 gold") {
///   Emit("payGold", ["amount": 10])
///   Merchant ~ "Thank you!"
/// }
/// ```
public func Choice(
  _ text: String,
  @BranchBuilder content: () -> [DialogElement]
) -> DialogElement {
  .choice(text: text, condition: nil, content: content())
}

/// Create a conditional choice option.
///
/// ### Example
/// ```swift
/// Choice("Pay 10 gold", when: { game.gold >= 10 }) {
///   Emit("payGold", ["amount": 10])
///   Merchant ~ "Thank you!"
/// }
/// ```
public func Choice(
  _ text: String,
  when condition: @escaping () -> Bool,
  @BranchBuilder content: () -> [DialogElement]
) -> DialogElement {
  .choice(text: text, condition: condition, content: content())
}

/// Jump to another branch.
///
/// ### Example
/// ```swift
/// > "Go to market" {
///   Guard ~ "Safe travels!"
///   Jump("market")
/// }
/// ```
public func Jump(_ branchId: String) -> DialogElement {
  .jump(branchId: branchId)
}

// MARK: - Dialog Elements

/// Elements that can appear in a branch.
public indirect enum DialogElement {
  case line(speaker: String, text: String)
  case choice(text: String, condition: (() -> Bool)?, content: [DialogElement])
  case emit(name: String, data: [String: Any]?)
  case conditional(condition: () -> Bool, content: [DialogElement])
  case jump(branchId: String)
  case end
}

/// Marker for ending a dialog branch.
public var End: DialogElement { .end }

/// Emit a custom event to the DialogBus.
///
/// ### Example
/// ```swift
/// Branch("merchant") {
///   Merchant ~ "Here's your reward!"
///   Emit("giveGold", ["amount": 100])
/// }
/// ```
public func Emit(_ name: String, _ data: [String: Any]? = nil) -> DialogElement {
  .emit(name: name, data: data)
}

/// Conditional block that re-evaluates its condition at runtime.
///
/// ### Example
/// ```swift
/// When { game.hasKey } {
///   Guard ~ "I see you have the key!"
///   Jump("unlocked_path")
/// }
/// ```
public func When(
  _ condition: @escaping () -> Bool,
  @BranchBuilder content: () -> [DialogElement]
) -> DialogElement {
  .conditional(condition: condition, content: content())
}

// MARK: - Branch & Dialog Definitions

/// A branch within a dialog containing dialog elements.
public struct BranchDefinition {
  public let id: String
  public let elements: [DialogElement]

  public init(id: String, elements: [DialogElement]) {
    self.id = id
    self.elements = elements
  }
}

/// A complete dialog containing multiple branches.
public struct DialogDefinition {
  public let id: String
  public let branches: [BranchDefinition]

  public init(id: String = UUID().uuidString, branches: [BranchDefinition]) {
    self.id = id
    self.branches = branches
  }

  /// Get a branch by its ID.
  public func branch(_ id: String) -> BranchDefinition? {
    branches.first { $0.id == id }
  }

  /// The first branch in the dialog.
  public var firstBranch: BranchDefinition? {
    branches.first
  }
}

// MARK: - Result Builders

/// Result builder for constructing branch content.
@resultBuilder
public struct BranchBuilder {
  public static func buildExpression(_ element: DialogElement) -> [DialogElement] {
    [element]
  }

  public static func buildBlock(_ components: [DialogElement]...) -> [DialogElement] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [DialogElement]?) -> [DialogElement] {
    component ?? []
  }

  public static func buildEither(first component: [DialogElement]) -> [DialogElement] {
    component
  }

  public static func buildEither(second component: [DialogElement]) -> [DialogElement] {
    component
  }

  public static func buildArray(_ components: [[DialogElement]]) -> [DialogElement] {
    components.flatMap { $0 }
  }
}

/// Result builder for constructing dialogs from branches.
@resultBuilder
public struct DialogBuilder {
  public static func buildExpression(_ branch: BranchDefinition) -> [BranchDefinition] {
    [branch]
  }

  public static func buildBlock(_ components: [BranchDefinition]...) -> [BranchDefinition] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [BranchDefinition]?) -> [BranchDefinition] {
    component ?? []
  }

  public static func buildEither(first component: [BranchDefinition]) -> [BranchDefinition] {
    component
  }

  public static func buildEither(second component: [BranchDefinition]) -> [BranchDefinition] {
    component
  }

  public static func buildArray(_ components: [[BranchDefinition]]) -> [BranchDefinition] {
    components.flatMap { $0 }
  }
}

// MARK: - Entry Point Functions

/// Create a dialog from branches.
///
/// ### Example
/// ```swift
/// let myDialog = Dialog {
///   Branch("intro") {
///     Guard ~ "Welcome!"
///   }
///   Branch("farewell") {
///     Guard ~ "Goodbye!"
///   }
/// }
/// ```
public func Dialog(
  id: String = UUID().uuidString,
  @DialogBuilder content: () -> [BranchDefinition]
) -> DialogDefinition {
  DialogDefinition(id: id, branches: content())
}

/// Create a branch with dialog elements.
///
/// ### Example
/// ```swift
/// Branch("checkpoint") {
///   Guard ~ "Halt!"
///   Choice("I'm friendly") {
///     Guard ~ "Proceed."
///   }
/// }
/// ```
public func Branch(
  _ id: String,
  @BranchBuilder content: () -> [DialogElement]
) -> BranchDefinition {
  BranchDefinition(id: id, elements: content())
}
