import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct DialogBox: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>

    var vm: GameViewState { state.wrappedValue }

    @State var isVisible = false

    var body: some GView {
      Control$ {
        SwiftGodotBuilder.DialogBox(
          isVisible: $isVisible,
          dialogRunner: { vm.dialogRunner },
          speakerColors: Chapter26.buildSpeakerColors()
        ) {
          // onEnd callback
          if let npcId = vm.currentNPCId {
            DialogEvent.ended(npcId: npcId).emit()
          }
          vm.cleanupDialog()
          router.scene = .playing
        }
      }
      .watch(router, \.scene) { _, scene in
        isVisible = scene == .dialog
      }
    }
  }
}
