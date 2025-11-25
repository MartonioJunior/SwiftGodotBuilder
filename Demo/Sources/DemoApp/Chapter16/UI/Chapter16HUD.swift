import SwiftGodot
import SwiftGodotBuilder

extension Chapter16 {
  struct HUD: GView {
    let state: ObservableState<GameViewState>

    let palette = Palette()

    var body: some GView {
      VBoxContainer$ {
        // Title
        Label$()
          .text("CHAPTER 16")
          .horizontalAlignment(.center)
          .theme(["fontColor": palette.whiteTranslucent])

        // Stats row
        HBoxContainer$ {
          // Health hearts
          Label$().text("HP:")
          Label$()
            .text(state.healthDisplay)
            .theme(["fontColor": palette.red])

          Control$().sizeH(.expandFill)

          // Lives
          Label$()
            .text(state.livesDisplay)
            .theme(["fontColor": palette.lightGray])

          Control$().sizeH(.expandFill)

          // Coins
          Label$()
            .text(state.coinsDisplay)
            .theme(["fontColor": palette.yellow])

          Control$().sizeH(.expandFill)

          // Inventory (key icon)
          Label$()
            .text(state.inventoryDisplay)
            .theme(["fontColor": palette.gold])

          Control$().sizeH(.expandFill)

          // Weapon type
          Label$()
            .text(state.weaponDisplay)
            .theme(["fontColor": palette.lightGray])

          Control$().sizeH(.expandFill)

          // Ammo
          Label$()
            .text(state.ammoDisplay)
            .theme(["fontColor": palette.cyan])

          Control$().sizeH(.expandFill)

          // Score
          Label$()
            .text(state.scoreDisplay)
            .theme(["fontColor": palette.greenLight])

          Control$().sizeH(.expandFill)

          // Timer
          Label$()
            .text(state.playTimeDisplay)
            .theme(["fontColor": palette.gray])
        }
        .sizeH(.expandFill)
      }
      .anchors(.topWide)
      .offset(top: 0, right: -10, bottom: 0, left: 10)
      .visible(state.isPlaying)
    }
  }
}
