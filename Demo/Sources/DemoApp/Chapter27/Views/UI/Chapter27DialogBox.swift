import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct DialogBox: GView {
    let router: ObservableState<GameRouter>
    let dialog: ObservableState<DialogGameState>

    var ds: DialogGameState { dialog.wrappedValue }

    @State var isVisible = false

    var body: some GView {
      Control$ {
        SwiftGodotBuilder.DialogBox(
          isVisible: $isVisible,
          dialogRunner: { ds.dialogRunner },
          speakerColors: Chapter27.buildSpeakerColors()
        ) {
          // onEnd callback
          if let npcId = ds.currentNPCId {
            DialogEvent.ended(npcId: npcId).emit()
          }
          ds.cleanupDialog()
          router.scene = .playing
        }
      }
      .watch(router, \.scene) { _, scene in
        isVisible = scene == .dialog
      }
    }
  }
}
