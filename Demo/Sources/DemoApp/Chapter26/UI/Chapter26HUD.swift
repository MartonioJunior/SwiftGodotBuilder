import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct HUD: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>
    let player: ObservableState<PlayerState>

    let palette = Palette.shared

    var body: some GView {
      VBoxContainer$ {
        HBoxContainer$ {
          // Hearts
          HBoxContainer$ {
            HeartIcon(index: 0, player: player)
            HeartIcon(index: 1, player: player)
            HeartIcon(index: 2, player: player)
          }
          .theme(["separation": 1])

          // Lives
          HBoxContainer$ {
            Control$ {
              AseSprite$(path: "Hero")
                .autoplay("Sword_Idle")
                .centered(false)
            }
            .minSize([8, 8])

            Label$()
              .text(player.livesCountDisplay)
              .theme(["fontColor": palette.lightGray])
          }
          .theme(["separation": 1])

          // Coins
          HBoxContainer$ {
            Control$ {
              AseSprite$(path: "Items")
                .autoplay("coinGold")
                .centered(false)
                .paused()
            }
            .minSize([8, 8])

            Label$()
              .text(state.coinsCountDisplay)
              .theme(["fontColor": palette.yellow])
          }
          .theme(["separation": 1])

          // Key
          Control$ {
            AseSprite$(path: "Items")
              .autoplay("key")
              .centered(false)
          }
          .minSize([8, 8])
          .watch(player, \.hasKey) { control, hasKey in
            control.visible = hasKey
          }

          // Weapon
          HBoxContainer$ {
            WeaponIcon(player: player)

            Label$()
              .text(player.ammoDisplay)
              .theme(["fontColor": palette.cyan])
          }
          .theme(["separation": 1])
        }
        .theme(["separation": 10])
      }
      .anchors(.topWide)
      .offset(top: 0, right: -10, bottom: 0, left: 10)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .playing
      }
    }
  }

  /// Sprite heart icon that reactively updates based on health
  struct HeartIcon: GView {
    let index: Int
    let player: ObservableState<PlayerState>

    var body: some GView {
      Control$ {
        AseSprite$(path: "Items")
          .centered(false)
          .watch(player, \.playerHealth) { sprite, health in
            sprite.play(health > index ? "heart" : "heartOpen")
          }
      }
      .minSize([8, 8])
    }
  }

  /// Sprite weapon icon that reactively updates based on current weapon
  struct WeaponIcon: GView {
    let player: ObservableState<PlayerState>

    var body: some GView {
      Control$ {
        AseSprite$(path: "Items")
          .centered(false)
          .watch(player, \.currentWeapon) { sprite, weapon in
            sprite.play(weapon == .melee ? "sword1" : "bow1")
          }
      }
      .minSize([8, 8])
    }
  }
}
