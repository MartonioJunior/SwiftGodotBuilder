import SwiftGodot

/// A self-contained dialog manager that handles dialog lifecycle automatically.
///
/// Add this to your scene and it will:
/// - Listen for dialog requests from actors with `.dialog { }` modifier
/// - Show the dialog UI automatically
/// - Emit `dialogActive` events for auto-pause integration
/// - Clean up when dialog ends
///
/// ### Usage
/// ```swift
/// Node2D$ {
///   DialogManager(speakerColors: ["Guard": .blue, "Merchant": .gold])
///
///   // NPCs with .dialog modifier will trigger automatically
///   SkullNPC(actor: skullActor)
/// }
/// ```
public struct DialogManager: GView {
  let speakerColors: [String: Color]
  let typewriterSpeed: Float

  @State private var isVisible = false
  @State private var currentActorId = 0
  @State private var currentDialogId = ""

  // Runner holder (not @State since DialogRunner isn't Equatable)
  private final class RunnerHolder {
    var runner: DialogRunner?
  }

  private let runnerHolder = RunnerHolder()

  public init(
    speakerColors: [String: Color] = [:],
    typewriterSpeed: Float = 30.0
  ) {
    self.speakerColors = speakerColors
    self.typewriterSpeed = typewriterSpeed
  }

  public var body: some GView {
    CanvasLayer$ {
      DialogBox(
        isVisible: $isVisible,
        dialogRunner: { runnerHolder.runner },
        speakerColors: speakerColors,
        typewriterSpeed: typewriterSpeed
      ) {
        handleDialogEnd()
      }
    }
    .processMode(.always)
    .onEvent(DialogManagerEvent.self) { _, event in
      if case let .dialogRequested(actorId, dialog, branchId) = event {
        startDialog(actorId: actorId, dialog: dialog, branchId: branchId)
      }
    }
  }

  private func startDialog(actorId: Int, dialog: DialogDefinition, branchId: String?) {
    guard !isVisible else { return }

    currentActorId = actorId
    currentDialogId = dialog.id

    let runner = DialogRunner(dialog: dialog)
    runner.pendingBranchId = branchId
    runnerHolder.runner = runner

    DialogManagerEvent.dialogActive(true).emit()
    isVisible = true
  }

  private func handleDialogEnd() {
    isVisible = false
    DialogManagerEvent.dialogActive(false).emit()
    DialogManagerEvent.dialogEnded(actorId: currentActorId, dialogId: currentDialogId).emit()
    runnerHolder.runner = nil
  }
}
