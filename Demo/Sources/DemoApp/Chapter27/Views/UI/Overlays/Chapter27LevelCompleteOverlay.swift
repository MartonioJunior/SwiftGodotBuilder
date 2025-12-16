import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct LevelCompleteOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var vm: ProjectState { state.wrappedValue }
    var pgs: PlayerGameState { player.wrappedValue }
    var gp: GameProgress { progress.wrappedValue }

    @State var firstResponder: Button?
    @State var isNewBest = false
    @State var previousBest = ""
    @State var hasNextLevel = true

    // Snapshot values captured when overlay becomes visible
    @State var medalName = ""
    @State var medalColor = Color.white
    @State var medalAnimation: String?
    @State var timeDisplay = ""
    @State var coinsDisplay = ""
    @State var deathsDisplay = ""
    @State var scoreDisplay = ""
    @State var levelName = ""

    var body: some GView {
      Node2D$ {
        OverlayPanel(panelStyle: palette.victoryPanelStyle, separation: 2) {
          HeaderLabel("LEVEL COMPLETE!", size: 24, color: palette.green)

          Label$()
            .text($levelName)
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.cyan])

          Spacer(4)

          // Medal display
          HBoxContainer$ {
            Control$ {
              AseSprite$(path: "Items")
                .scale([2, 2])
                .watch($medalAnimation) { sprite, anim in
                  if let anim {
                    sprite.play(anim)
                    sprite.visible = true
                  } else {
                    sprite.visible = false
                  }
                }
            }
            .minSize([16, 16])

            VBoxContainer$ {
              Label$()
                .text($medalName)
                .theme(["fontColor": $medalColor])

              Label$()
                .text($timeDisplay)
                .theme(["fontColor": palette.white])
            }

            // New best indicator
            If($isNewBest) {
              Label$()
                .text("NEW BEST TIME!")
                .horizontalAlignment(.center)
                .theme(["fontColor": palette.gold])
            }
            .Else {
              Label$()
                .bind(\.text, to: $previousBest) { "Best: \($0)" }
                .horizontalAlignment(.center)
                .theme(["fontColor": palette.gray])
            }
          }
          .theme(["separation": 8])

          Spacer(4)

          HBoxContainer$ {
            Label$()
              .text($coinsDisplay)
              .theme(["fontColor": palette.yellow])

            Label$()
              .text($deathsDisplay)
              .theme(["fontColor": palette.redLight])

            Label$()
              .text($scoreDisplay)
              .theme(["fontColor": palette.white])
          }
          .theme(["separation": 16])

          Spacer(4)

          HBoxContainer$ {
            If($hasNextLevel) {
              AnimatedButton("Next Level", width: 100, color: .green, ref: $firstResponder) {
                goToNextLevel()
              }
            }

            AnimatedButton("Retry", width: 100, color: .cyan) {
              retryLevel()
            }

            AnimatedButton("Leaderboard", width: 100, color: .yellow) {
              vm.setLeaderboardLevel(vm.currentLevelId)
              router.scene = .leaderboard
            }

            AnimatedButton("Menu", width: 100, color: .gray) {
              goToMenu()
            }
          }
          .theme(["separation": 4])
        }
      }
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .levelComplete
        if scene == .levelComplete {
          captureSnapshot()
          firstResponder?.grabFocus()
        }
      }
    }

    func captureSnapshot() {
      guard !vm.currentLevelId.isEmpty else { return }

      let levelProgress = gp.getProgress(for: vm.currentLevelId)
      let currentTime = vm.playTime
      let medal = vm.currentMedal

      // Capture all display values
      levelName = vm.levelNameDisplay
      medalName = "\(medal.name) Medal"
      medalColor = Color(code: medal.color)
      medalAnimation = medal.animation
      timeDisplay = vm.playTimeDisplay
      coinsDisplay = pgs.coinsDisplay
      deathsDisplay = pgs.deathsDisplay
      scoreDisplay = pgs.finalScoreDisplay

      // Check if next level exists
      hasNextLevel = !vm.nextLevelId.isEmpty

      // Check if this is a new best
      if levelProgress.leaderboard.count <= 1 {
        isNewBest = true
        previousBest = "--:--.--"
      } else if currentTime <= levelProgress.leaderboard[0].time {
        isNewBest = true
        previousBest = levelProgress.leaderboard[1].timeFormatted
      } else {
        isNewBest = false
        previousBest = levelProgress.bestTimeFormatted
      }
    }

    func goToNextLevel() {
      let nextId = vm.nextLevelId
      guard !nextId.isEmpty else {
        goToMenu()
        return
      }
      router.navigate(to: .playing, transition: .fade(duration: 0.6)) {
        vm.prepareLevel(nextId)
        pgs.fullReset()
      }
    }

    func retryLevel() {
      router.navigate(to: .playing, transition: .fade(duration: 0.6)) {
        vm.prepareLevel(vm.currentLevelId)
        pgs.fullReset()
      }
    }

    func goToMenu() {
      router.navigate(to: .levelSelect, transition: .fade(duration: 0.6))
    }
  }
}
