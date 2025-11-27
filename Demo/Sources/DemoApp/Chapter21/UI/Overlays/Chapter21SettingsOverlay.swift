import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct SettingsOverlay: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>
    @State var previousGameState: GameState = .levelSelect
    @State var firstSlider: HSlider?

    let palette = Palette.shared

    var settingsButtons: some GView {
      VBoxContainer$ {
        HBoxContainer$ {
          MenuButton("Reset", width: 70, color: .yellow) {
            settings.wrappedValue.resetToDefaults()
          }
          MenuButton("Save", width: 70, color: .green) {
            settings.wrappedValue.savePersistence()
          }
          MenuButton("Clear", width: 70, color: .purple) {
            progress.wrappedValue.clearProgress()
          }
          MenuButton("Back", width: 70, color: .cyan) {
            state.wrappedValue.gameState = previousGameState
          }
        }
        .theme(["separation": 4])

        InfoLabel("[A] Select  [D-Pad] Navigate  [B] Back")
      }
      .theme(["separation": 2])
    }

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          MarginContainer$ {
            VBoxContainer$ {
              HeaderLabel("SETTINGS", size: 16, color: palette.purple)

              Label$()
                .text("AUDIO")
                .horizontalAlignment(.left)
                .theme(["fontColor": palette.white])

              HBoxContainer$ {
                Label$()
                  .text("Master")
                  .minSize([70, 0])
                  .theme(["fontColor": palette.lightGray])

                HSlider$()
                  .minValue(0)
                  .maxValue(1)
                  .step(0.01)
                  .value(settings.masterVolume)
                  .minSize([100, 0])
                  .focusMode(.all)
                  .ref($firstSlider)

                Label$()
                  .text(settings.masterVolumeDisplay)
                  .minSize([35, 0])
                  .theme(["fontColor": palette.cyan])
              }

              HBoxContainer$ {
                Label$()
                  .text("Music")
                  .minSize([70, 0])
                  .theme(["fontColor": palette.lightGray])

                HSlider$()
                  .minValue(0)
                  .maxValue(1)
                  .step(0.01)
                  .value(settings.musicVolume)
                  .minSize([100, 0])
                  .focusMode(.all)

                Label$()
                  .text(settings.musicVolumeDisplay)
                  .minSize([35, 0])
                  .theme(["fontColor": palette.cyan])
              }

              HBoxContainer$ {
                Label$()
                  .text("SFX")
                  .minSize([70, 0])
                  .theme(["fontColor": palette.lightGray])

                HSlider$()
                  .minValue(0)
                  .maxValue(1)
                  .step(0.01)
                  .value(settings.sfxVolume)
                  .minSize([100, 0])
                  .focusMode(.all)

                Label$()
                  .text(settings.sfxVolumeDisplay)
                  .minSize([35, 0])
                  .theme(["fontColor": palette.cyan])
              }

              Spacer(4)

              Label$()
                .text("DISPLAY")
                .horizontalAlignment(.left)
                .theme(["fontColor": palette.white])

              HBoxContainer$ {
                Label$()
                  .text("Fullscreen")
                  .minSize([70, 0])
                  .theme(["fontColor": palette.lightGray])

                CheckButton$()
                  .pressed(settings.fullscreen)
                  .focusMode(.all)
                  .onSignal(\.toggled) { [settings] _, isFullscreen in
                    DisplayServer.windowSetMode(isFullscreen ? .fullscreen : .windowed)
                    settings.wrappedValue.savePersistence()
                  }
              }

              Spacer(4)

              settingsButtons
            }
            .theme(["separation": 2])
          }
          .theme(["marginTop": 4, "marginRight": 4, "marginBottom": 4, "marginLeft": 4])
        }
        .theme("panel", palette.settingsPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isSettings)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .settings {
          firstSlider?.grabFocus()
        }
      }
      .onProcess { [state, previousGameState] _, _ in
        guard state.wrappedValue.isSettings else { return }
        if Action("ui_cancel").isJustPressed {
          state.wrappedValue.gameState = previousGameState
        }
      }
    }
  }
}
