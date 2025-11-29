import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  struct CharacterOverlay: GView {
    let state: ObservableState<GameViewState>
    @State var showOverlay = false

    let palette = Palette.shared

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("CHARACTER SHEET", size: 16, color: palette.cyan)

            HBoxContainer$ {
              PanelContainer$ {
                VBoxContainer$ {
                  InfoLabel("HEALTH", color: palette.healthHeader)

                  Label$()
                    .text(state.healthDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontSize": 16, "fontColor": palette.red])

                  Label$()
                    .text(state.livesDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontColor": palette.lightGray])
                }
              }
              .theme("panel", palette.healthSectionStyle)

              PanelContainer$ {
                VBoxContainer$ {
                  InfoLabel("INVENTORY", color: palette.yellowBright)

                  Label$()
                    .text(state.coinsDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontSize": 16, "fontColor": palette.yellow])

                  Label$()
                    .text("🔑")
                    .horizontalAlignment(.center)
                    .visible(state.hasKey)
                    .theme(["fontColor": palette.gold])
                }
              }
              .theme("panel", palette.inventorySectionStyle)

              PanelContainer$ {
                VBoxContainer$ {
                  InfoLabel("WEAPONS", color: palette.weaponHeader)

                  Label$()
                    .text(state.weaponDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontSize": 16, "fontColor": palette.lightGray])

                  Label$()
                    .text(state.ammoDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontColor": palette.cyan])
                }
              }
              .theme("panel", palette.weaponSectionStyle)

              PanelContainer$ {
                VBoxContainer$ {
                  InfoLabel("STATS", color: palette.greenLight)

                  Label$()
                    .text(state.scoreDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontSize": 16, "fontColor": palette.greenLight])

                  Label$()
                    .text(state.playTimeDisplay)
                    .horizontalAlignment(.center)
                    .theme(["fontColor": palette.gray])
                }
              }
              .theme("panel", palette.statsSectionStyle)
            }
            .theme(["separation": 4])
          }
          .theme(["separation": 8])
        }
        .theme("panel", palette.characterPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible($showOverlay)
      .onProcess { _, _ in
        if Action("character_sheet").isJustPressed {
          showOverlay.toggle()
        }
      }
    }
  }
}
