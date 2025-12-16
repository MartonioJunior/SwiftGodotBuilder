import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct GameOverOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>

    let palette = Palette.shared

    var vm: ProjectState { state.wrappedValue }
    var pgs: PlayerGameState { player.wrappedValue }

    @State var firstResponder: Button?

    // Snapshot values captured when overlay becomes visible
    @State var levelName = ""
    @State var scoreDisplay = ""
    @State var coinsDisplay = ""
    @State var timeDisplay = ""
    @State var deathsDisplay = ""

    var body: some GView {
      Node2D$ {
        OverlayPanel(panelStyle: palette.gameOverPanelStyle) {
          HeaderLabel("GAME OVER", size: 48, color: palette.redLight)

          Label$()
            .text($levelName)
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.gray])

          Spacer()

          Label$()
            .text($scoreDisplay)
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.yellow])

          Label$()
            .text($coinsDisplay)
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.gold])

          Label$()
            .text($timeDisplay)
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.lightGray])

          Label$()
            .text($deathsDisplay)
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.redLight])

          Spacer()

          HBoxContainer$ {
            BounceButton("Retry", width: 120, color: .cyan, ref: $firstResponder) {
              retryLevel()
            }
            AnimatedButton("Menu", width: 120, color: .gray) {
              goToMenu()
            }
          }
          .theme(["separation": 8])
        }
      }
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .gameOver
        if scene == .gameOver {
          captureSnapshot()
          firstResponder?.grabFocus()
        }
      }
    }

    func captureSnapshot() {
      levelName = vm.levelNameDisplay
      scoreDisplay = pgs.finalScoreDisplay
      coinsDisplay = pgs.coinsDisplay
      timeDisplay = vm.playTimeDisplay
      deathsDisplay = pgs.deathsDisplay
    }

    func retryLevel() {
      router.navigate(to: .playing, transition: .iris(duration: 1.0, center: [0.5, 0.5])) {
        vm.prepareLevel(vm.currentLevelId)
        pgs.fullReset()
      }
    }

    func goToMenu() {
      router.navigate(to: .levelSelect, transition: .fade(duration: 0.6))
    }
  }
}
