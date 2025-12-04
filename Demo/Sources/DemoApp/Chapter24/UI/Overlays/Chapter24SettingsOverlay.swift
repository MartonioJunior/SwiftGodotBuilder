import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct SettingsOverlay: GView {
    let router: ObservableState<GameRouter>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>
    @State var previousScene: GameState = .levelSelect
    @State var firstResponder: HSlider?

    let palette = Palette.shared

    private var gs: GameSettings { settings.wrappedValue }
    private var gp: GameProgress { progress.wrappedValue }

    var settingsButtons: some GView {
      VBoxContainer$ {
        HBoxContainer$ {
          MenuButton("Reset", width: 70, color: .yellow) {
            gs.resetToDefaults()
          }
          MenuButton("Save", width: 70, color: .green) {
            gs.savePersistence()
          }
          MenuButton("Clear", width: 70, color: .purple) {
            gp.clearProgress()
          }
          MenuButton("Back", width: 70, color: .cyan) {
            router.scene = previousScene
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
                  .ref($firstResponder)

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
                  .onSignal(\.toggled) { _, isFullscreen in
                    DisplayServer.windowSetMode(isFullscreen ? .fullscreen : .windowed)
                    gs.savePersistence()
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
