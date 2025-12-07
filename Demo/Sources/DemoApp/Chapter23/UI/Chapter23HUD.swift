import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct HUD: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>

    let palette = Palette.shared

    var body: some GView {
      VBoxContainer$ {
        Label$()
          .text("CHAPTER 23")
          .horizontalAlignment(.center)
          .theme(["fontColor": palette.whiteTranslucent])

        HBoxContainer$ {
          HBoxContainer$ {
            Label$().text("HP:")

            Label$()
              .text(state.healthDisplay)
              .theme(["fontColor": palette.red])
          }
          .sizeH(.expandFill)

          Label$()
            .text(state.livesDisplay)
            .theme(["fontColor": palette.lightGray])
            .sizeH(.expandFill)

          Label$()
            .text(state.coinsDisplay)
            .theme(["fontColor": palette.yellow])
            .sizeH(.expandFill)

          Label$()
            .text(state.inventoryDisplay)
            .theme(["fontColor": palette.gold])
            .sizeH(.expandFill)

          Label$()
            .text(state.weaponDisplay)
            .theme(["fontColor": palette.lightGray])
            .sizeH(.expandFill)

          Label$()
            .text(state.ammoDisplay)
            .theme(["fontColor": palette.cyan])
            .sizeH(.expandFill)

          Label$()
            .text(state.scoreDisplay)
            .theme(["fontColor": palette.greenLight])
            .sizeH(.expandFill)

          Label$()
            .text(state.playTimeDisplay)
            .theme(["fontColor": palette.gray])
            .sizeH(.expandFill)
        }
      }
      .anchors(.topWide)
      .offset(top: 0, right: -10, bottom: 0, left: 10)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .playing
      }
    }
  }
}
