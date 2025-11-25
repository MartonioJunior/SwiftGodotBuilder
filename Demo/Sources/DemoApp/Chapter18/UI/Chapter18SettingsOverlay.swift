import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct SettingsOverlay: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>
    @State var previousGameState: GameState = .levelSelect
    @State var firstSlider: HSlider?

    let palette = Palette()

    var settingsButtons: some GView {
      VBoxContainer$ {
        HBoxContainer$ {
          Button$()
            .text("Reset")
            .minSize([70, 0])
            .focusMode(.all)
            .styleBoxes(palette.yellowButtonStylesWithFocus)
            .onSignal(\.pressed) { [settings] _ in
              settings.wrappedValue.resetToDefaults()
            }
          Button$()
            .text("Save")
            .minSize([70, 0])
            .focusMode(.all)
            .styleBoxes(palette.greenButtonStylesWithFocus)
            .onSignal(\.pressed) { [settings] _ in
              settings.wrappedValue.savePersistence()
            }
          Button$()
            .text("Clear")
            .minSize([70, 0])
            .focusMode(.all)
            .styleBoxes(palette.purpleButtonStylesWithFocus)
            .onSignal(\.pressed) { [progress] _ in
              progress.wrappedValue.clearProgress()
            }
          Button$()
            .text("Back")
            .minSize([70, 0])
            .focusMode(.all)
            .styleBoxes(palette.cyanButtonStylesWithFocus)
            .onSignal(\.pressed) { [state, previousGameState] _ in
              state.wrappedValue.gameState = previousGameState
            }
        }
        .theme(["separation": 4])

        Label$()
          .text("[A] Select  [D-Pad] Navigate  [B] Back")
          .horizontalAlignment(.center)
          .theme(["fontColor": palette.darkGray])
      }
      .theme(["separation": 2])
    }

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          MarginContainer$ {
            VBoxContainer$ {
              Label$()
                .text("SETTINGS")
                .horizontalAlignment(.center)
                .theme(["fontSize": 16, "fontColor": palette.purple])

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

              Control$().minSize([0, 4])

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

              Control$().minSize([0, 4])

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
      .watch(state, \.gameState) { [self] _, gameState in
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
