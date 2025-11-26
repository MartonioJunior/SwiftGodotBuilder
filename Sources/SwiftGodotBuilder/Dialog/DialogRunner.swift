import Foundation
import SwiftGodot

/// Runtime state for a dialog line being displayed.
public struct DialogLine {
  public let speaker: String
  public let text: String

  public init(speaker: String, text: String) {
    self.speaker = speaker
    self.text = text
  }
}

/// A choice available to the player.
public struct DialogChoice {
  public let index: Int
  public let text: String

  public init(index: Int, text: String) {
    self.index = index
    self.text = text
  }
}

/// Runs a dialog, handling state transitions and emitting events.
///
/// ### Example
/// ```swift
/// let runner = DialogRunner(dialog: myDialog)
///
/// runner.onLine = { line in
///   dialogLabel.text = line.text
///   speakerLabel.text = line.speaker
/// }
///
/// runner.onChoices = { choices in
///   showChoiceButtons(choices)
/// }
///
/// runner.onEnd = {
///   hideDialog()
/// }
///
/// runner.start()
/// ```
public class DialogRunner {
  public let dialog: DialogDefinition

  private var currentBranchId: String?
  private var currentElements: [DialogElement] = []
  private var currentIndex = 0
  private var pendingChoices: [(index: Int, text: String, content: [DialogElement])] = []

  /// Branch ID to start from (set before calling start())
  public var pendingBranchId: String?

  // Callbacks
  public var onLine: ((DialogLine) -> Void)?
  public var onChoices: (([DialogChoice]) -> Void)?
  public var onEnd: (() -> Void)?

  public init(dialog: DialogDefinition) {
    self.dialog = dialog
  }

  /// Start the dialog from the first branch or a specific branch.
  public func start(branchId: String? = nil) {
    let targetId = branchId ?? dialog.firstBranch?.id
    guard let id = targetId, let branch = dialog.branch(id) else {
      onEnd?()
      return
    }

    currentBranchId = id
    currentElements = evaluateElements(branch.elements)
    currentIndex = 0

    DialogBusEvent.dialogStarted(dialogId: dialog.id).emit()
    DialogBusEvent.branchStarted(dialogId: dialog.id, branchId: id).emit()

    processNext()
  }

  /// Advance to the next dialog element.
  public func advance() {
    guard pendingChoices.isEmpty else { return } // Must select a choice first
    currentIndex += 1
    processNext()
  }

  /// Select a choice by its index.
  public func selectChoice(_ index: Int) {
    guard index < pendingChoices.count else { return }

    let choice = pendingChoices[index]
    DialogBusEvent.choiceMade(
      dialogId: dialog.id,
      branchId: currentBranchId ?? "",
      choiceText: choice.text
    ).emit()

    // Execute the choice content
    pendingChoices = []
    let content = evaluateElements(choice.content)

    // Insert choice content into the element stream
    let remaining = Array(currentElements.dropFirst(currentIndex + 1))
    currentElements = Array(currentElements.prefix(currentIndex + 1)) + content + remaining
    currentIndex += 1

    processNext()
  }

  /// Check if there are pending choices.
  public var hasChoices: Bool {
    !pendingChoices.isEmpty
  }

  /// Get available choices (for UI).
  public var availableChoices: [DialogChoice] {
    pendingChoices.map {
      let translatedText = String(TranslationServer.translate(message: StringName($0.text)))
      return DialogChoice(index: $0.index, text: translatedText)
    }
  }

  // MARK: - Private

  private func processNext() {
    guard currentIndex < currentElements.count else {
      endCurrentBranch()
      return
    }

    let element = currentElements[currentIndex]

    switch element {
    case let .line(speaker, text):
      let translatedSpeaker = String(TranslationServer.translate(message: StringName(speaker)))
      let translatedText = String(TranslationServer.translate(message: StringName(text)))
      let line = DialogLine(speaker: translatedSpeaker, text: translatedText)
      DialogBusEvent.lineSpoken(speaker: translatedSpeaker, text: translatedText).emit()
      onLine?(line)

    case .choice:
      // Gather all consecutive choices
      gatherChoices()

    case let .emit(name, data):
      DialogBusEvent.emitted(name: name, data: data).emit()
      currentIndex += 1
      processNext()

    case let .conditional(condition, content):
      if condition() {
        // Insert conditional content
        let evaluated = evaluateElements(content)
        let remaining = Array(currentElements.dropFirst(currentIndex + 1))
        currentElements = Array(currentElements.prefix(currentIndex)) + evaluated + remaining
        processNext()
      } else {
        currentIndex += 1
        processNext()
      }

    case let .jump(branchId):
      jumpToBranch(branchId)

    case .end:
      endDialog()
    }
  }

  private func gatherChoices() {
    pendingChoices = []
    var choiceIndex = 0

    // Collect all consecutive choices starting from current position
    var i = currentIndex
    while i < currentElements.count {
      if case let .choice(text, condition, content) = currentElements[i] {
        // Check condition (nil means always available)
        if condition?() ?? true {
          pendingChoices.append((index: choiceIndex, text: text, content: content))
          choiceIndex += 1
        }
        i += 1
      } else {
        break
      }
    }

    // Update current index to after all choices
    currentIndex = i - 1

    if pendingChoices.isEmpty {
      // No valid choices, continue
      currentIndex += 1
      processNext()
    } else {
      onChoices?(availableChoices)
    }
  }

  private func evaluateElements(_ elements: [DialogElement]) -> [DialogElement] {
    // For now, return as-is. Conditions are evaluated at runtime during processing.
    elements
  }

  private func jumpToBranch(_ branchId: String) {
    guard let branch = dialog.branch(branchId) else {
      endDialog()
      return
    }

    if let currentId = currentBranchId {
      DialogBusEvent.branchEnded(dialogId: dialog.id, branchId: currentId).emit()
    }

    currentBranchId = branchId
    currentElements = evaluateElements(branch.elements)
    currentIndex = 0

    DialogBusEvent.branchStarted(dialogId: dialog.id, branchId: branchId).emit()
    processNext()
  }

  private func endCurrentBranch() {
    if let currentId = currentBranchId {
      DialogBusEvent.branchEnded(dialogId: dialog.id, branchId: currentId).emit()
    }
    endDialog()
  }

  private func endDialog() {
    DialogBusEvent.dialogEnded(dialogId: dialog.id).emit()
    currentBranchId = nil
    currentElements = []
    currentIndex = 0
    pendingChoices = []
    onEnd?()
  }
}
