import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct HUD: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>

    let palette = Palette.shared

    var body: some GView {
      VBoxContainer$ {
        HBoxContainer$ {
          // Hearts
          HBoxContainer$ {
            HeartIcon(index: 0, state: state)
            HeartIcon(index: 1, state: state)
            HeartIcon(index: 2, state: state)
          }
          .theme(["separation": 1])

          // Lives
          HBoxContainer$ {
            TextureRect$()
              .texture(PlayerSprite.walk1.texture)
              .minSize(PlayerSprite.walk1.minSize)
              .stretchMode(.keep)
              .expandMode(.ignoreSize)

            Label$()
              .text(state.livesCountDisplay)
              .theme(["fontColor": palette.lightGray])
          }
          .theme(["separation": 1])

          // Coins
          HBoxContainer$ {
            TextureRect$()
              .texture(ItemSprite.coin1.texture)
              .minSize(ItemSprite.coin1.minSize)
              .stretchMode(.keep)
              .expandMode(.ignoreSize)
            Label$()
              .text(state.coinsCountDisplay)
              .theme(["fontColor": palette.yellow])
          }
          .theme(["separation": 1])

          // Key
          TextureRect$()
            .minSize(ItemSprite.key.minSize)
            .watch(state, \.hasKey) { rect, hasKey in
              rect.texture = hasKey ? ItemSprite.key.texture : nil
            }

          // Weapon
          HBoxContainer$ {
            WeaponIcon(state: state)

            Label$()
              .text(state.ammoDisplay)
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
    let state: ObservableState<GameViewState>

    var body: some GView {
      TextureRect$()
        .minSize(ItemSprite.heartFull.minSize)
        .stretchMode(.keep)
        .expandMode(.ignoreSize)
        .watch(state, \.playerHealth) { rect, health in
          rect.texture = health > index ? ItemSprite.heartFull.texture : ItemSprite.heartOpen.texture
        }
    }
  }

  /// Sprite weapon icon that reactively updates based on current weapon
  struct WeaponIcon: GView {
    let state: ObservableState<GameViewState>

    var body: some GView {
      TextureRect$()
        .minSize(ItemSprite.sword1.minSize)
        .stretchMode(.keep)
        .expandMode(.ignoreSize)
        .watch(state, \.currentWeapon) { rect, weapon in
          rect.texture = weapon == .melee ? ItemSprite.sword1.texture : ItemSprite.bow1.texture
        }
    }
  }
}
