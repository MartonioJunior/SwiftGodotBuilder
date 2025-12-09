import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct LevelCompleteOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>
    let player: ObservableState<PlayerState>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var vm: GameViewState { state.wrappedValue }
    var ps: PlayerState { player.wrappedValue }
    var gp: GameProgress { progress.wrappedValue }

    @State var firstResponder: Button?
    @State var isNewBest = false
    @State var previousBest = ""
    @State var medalColorValue = Color.white
    @State var hasNextLevel = true

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("LEVEL COMPLETE!", size: 24, color: palette.green)
            LiveInfoLabel(state.levelNameDisplay, color: palette.cyan)

            Spacer(4)

            // Medal display
            HBoxContainer$ {
              Control$ {
                MedalIcon(state: state)
              }
              .minSize([16, 16])

              VBoxContainer$ {
                Label$()
                  .bind(\.text, to: state, \.currentMedal) { "\($0.name) Medal" }
                  .theme(["fontColor": $medalColorValue])

                Label$()
                  .text(state.playTimeDisplay)
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
                .text(state.coinsDisplay)
                .theme(["fontColor": palette.yellow])

              Label$()
                .text(state.deathsDisplay)
                .theme(["fontColor": palette.redLight])

              Label$()
                .text(state.finalScoreDisplay)
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
          .theme(["separation": 2])
        }
        .theme("panel", palette.victoryPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .levelComplete
        if scene == .levelComplete {
          guard !vm.currentLevelId.isEmpty else { return }
          let levelProgress = gp.getProgress(for: vm.currentLevelId)
          let currentTime = vm.playTime
          let medal = vm.currentMedal

          // Update medal color
          medalColorValue = Color(code: medal.color)

          // Check if next level exists
          hasNextLevel = !vm.nextLevelId.isEmpty

          // Check if this is a new best (leaderboard has the new time, so compare to 2nd best or check if only 1 entry)
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

          firstResponder?.grabFocus()
        }
      }
    }

    func goToNextLevel() {
      let nextId = vm.nextLevelId
      guard !nextId.isEmpty else {
        goToMenu()
        return
      }
      router.navigate(to: .playing, transition: .fade(duration: 0.6)) {
        vm.prepareLevel(nextId, player: ps)
      }
    }

    func retryLevel() {
      router.navigate(to: .playing, transition: .fade(duration: 0.6)) {
        vm.prepareLevel(vm.currentLevelId, player: ps)
      }
    }

    func goToMenu() {
      router.navigate(to: .levelSelect, transition: .fade(duration: 0.6))
    }
  }

  /// Sprite medal icon that reactively updates based on current medal
  struct MedalIcon: GView {
    let state: ObservableState<GameViewState>

    var body: some GView {
      AseSprite$(path: "Items")
        .scale([2, 2])
        .watch(state, \.currentMedal) { sprite, medal in
          if let anim = medal.animation {
            sprite.play(anim)
            sprite.visible = true
          } else {
            sprite.visible = false
          }
        }
    }
  }
}
