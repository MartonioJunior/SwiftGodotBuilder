import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct SettingsOverlay: GView {
    let router: ObservableState<GameRouter>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>
    @State var previousScene: GameState = .levelSelect
    @State var firstResponder: HSlider?

    let palette = Palette.shared

    var gs: GameSettings { settings.wrappedValue }
    var gp: GameProgress { progress.wrappedValue }

    var settingsButtons: some GView {
      VBoxContainer$ {
        HBoxContainer$ {
          MenuButton("Reset", width: 50, color: .yellow) {
            gs.resetToDefaults()
          }

          MenuButton("Clear", width: 50, color: .purple) {
            gp.clearProgress()
          }

          MenuButton("Back", width: 50, color: .cyan) {
            router.scene = previousScene
          }

          SpacerH()

          MenuButton("Save", width: 50, color: .green) {
            gs.savePersistence()
          }
        }
        .theme(["separation": 4])
      }
      .theme(["separation": 2])
    }

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          MarginContainer$ {
            VBoxContainer$ {
              HeaderLabel("SETTINGS", size: 8, color: palette.purple)

              Label$()
                .text("AUDIO")
                .horizontalAlignment(.left)
                .theme(["fontColor": palette.white])

              HBoxContainer$ {
                Label$()
                  .text("Master")
                  .minSize([50, 0])
                  .theme(["fontColor": palette.lightGray])

                HSlider$()
                  .minValue(0)
                  .maxValue(1)
                  .step(0.01)
                  .value(settings.masterVolume)
                  .minSize([100, 0])
                  .focusMode(.all)
                  .ref($firstResponder)

                Label$()
                  .text(settings.masterVolumeDisplay)
                  .minSize([35, 0])
                  .theme(["fontColor": palette.cyan])
              }

              HBoxContainer$ {
                Label$()
                  .text("Music")
                  .minSize([50, 0])
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
                  .minSize([50, 0])
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

              HBoxContainer$ {
                Label$()
                  .text("Fullscreen")
                  .minSize([50, 0])
                  .theme(["fontColor": palette.lightGray])

                CheckButton$()
                  .pressed(settings.fullscreen)
                  .focusMode(.all)
                  .onSignal(\.toggled) { _, isFullscreen in
                    DisplayServer.windowSetMode(isFullscreen ? .fullscreen : .windowed)
                    gs.savePersistence()
                  }
              }

              settingsButtons
            }
            .theme(["separation": 2])
          }
          .theme(["marginTop": 4, "marginRight": 4, "marginBottom": 4, "marginLeft": 4])
        }
        .theme("panel", palette.settingsPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .settings
        if scene == .settings {
          firstResponder?.grabFocus()
        }
      }
      .onProcess { _, _ in
        guard router.scene == .settings else { return }
        if Action("ui_cancel").isJustPressed {
          router.scene = previousScene
        }
      }
    }
  }
}
