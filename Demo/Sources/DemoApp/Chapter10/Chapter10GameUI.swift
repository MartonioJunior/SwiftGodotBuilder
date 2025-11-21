import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter10GameUI: GView {
  let state: ObservableState<Chapter10GameViewState>

  var body: some GView {
    CanvasLayer$ {
      Chapter10HUD(state: state)
      Chapter10MenuOverlay(state: state)
      Chapter10VictoryOverlay(state: state)
      Chapter10GameOverOverlay(state: state)

      // Screen flash effect
      ColorRect$()
        .color(Color(r: 1, g: 1, b: 1))
        .anchorsAndOffsets(.fullRect)
        .watch(state, \.screenFlashAlpha) { node, alpha in
          node.modulate = Color(r: 1, g: 1, b: 1, a: alpha)
          node.visible = alpha > 0
        }
    }
  }
}

// MARK: - HUD (In-Game UI)

struct Chapter10HUD: GView {
  let state: ObservableState<Chapter10GameViewState>

  var body: some GView {
    // Top HUD bar with proper layout
    VBoxContainer$ {
      // Title
      Label$()
        .text("CHAPTER 10: ADVANCED ATTACKS & RESOURCES")
        .horizontalAlignment(.center)
        .theme([
          "fontColor": Color(r: 1.0, g: 1.0, b: 1.0, a: 0.9),
        ])

      // Stats row
      HBoxContainer$ {
        // Health hearts
        Label$().text("HP:")
        Label$()
          .text(state.healthDisplay)
          .theme(["fontColor": Color(r: 1.0, g: 0.2, b: 0.2)])

        Control$().sizeH(.expandFill)

        // Coins
        Label$()
          .text(state.coinsDisplay)
          .theme(["fontColor": Color(r: 1.0, g: 0.9, b: 0.3)])

        Control$().sizeH(.expandFill)

        // Inventory (key icon)
        Label$()
          .text(state.inventoryDisplay)
          .theme(["fontColor": Color(r: 1.0, g: 0.8, b: 0.0)])

        Control$().sizeH(.expandFill)

        // Weapon type
        Label$()
          .text(state.weaponDisplay)
          .theme(["fontColor": Color(r: 0.9, g: 0.9, b: 0.9)])

        Control$().sizeH(.expandFill)

        // Ammo
        Label$()
          .text(state.ammoDisplay)
          .theme(["fontColor": Color(r: 0.3, g: 0.8, b: 1.0)])

        Control$().sizeH(.expandFill)

        // Score
        Label$()
          .text(state.scoreDisplay)
          .theme(["fontColor": Color(r: 0.5, g: 1.0, b: 0.5)])

        Control$().sizeH(.expandFill)

        // Timer
        Label$()
          .text(state.playTimeDisplay)
          .theme(["fontColor": Color(r: 0.7, g: 0.7, b: 0.7)])
      }
      .sizeH(.expandFill)
    }
    .anchors(.topWide)
    .offset(top: 0, right: -10, bottom: 0, left: 10)
    .watch(state, \.isPlaying) { node, isPlaying in
      node.visible = isPlaying
    }
  }
}

// MARK: - Menu Overlay

struct Chapter10MenuOverlay: GView {
  let state: ObservableState<Chapter10GameViewState>

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 10")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 32,
              "fontColor": Color(r: 0.3, g: 0.8, b: 1.0),
            ])

          Label$()
            .text("ADVANCED ATTACKS & RESOURCES")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 16,
              "fontColor": Color(r: 0.7, g: 0.7, b: 0.7),
            ])

          Control$().minSize([0, 20])

          Label$()
            .text("New Features:")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 16,
              "fontColor": Color(r: 1.0, g: 1.0, b: 1.0),
            ])

          Label$()
            .text("• Ranged Attack with Projectiles\n• Ammo System & Resource Management\n• Ammo Pickups\n• Attack Switching (Melee/Ranged)")
            .horizontalAlignment(.center)
            .theme(["fontColor": Color(r: 0.9, g: 0.9, b: 0.9)])

          Control$().minSize([0, 20])

          Label$()
            .text("Press SPACE to start")
            .horizontalAlignment(.center)
            .theme(["fontColor": Color(r: 1.0, g: 1.0, b: 0.5)])

          Control$().minSize([0, 10])

          Label$()
            .text("A/D = Move  |  SPACE = Jump  |  X = Attack  |  Q = Switch  |  SHIFT = Dash")
            .horizontalAlignment(.center)
            .theme(["fontColor": Color(r: 0.6, g: 0.6, b: 0.6)])
        }
      }
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isMenu) { node, isMenu in
      node.visible = isMenu
    }
  }
}

// MARK: - Victory Overlay

struct Chapter10VictoryOverlay: GView {
  let state: ObservableState<Chapter10GameViewState>

  var body: some GView {
    CenterContainer$ {
      VBoxContainer$ {
        Label$()
          .text("YOU WIN!")
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 48,
            "fontColor": Color(r: 0.3, g: 1.0, b: 0.3),
          ])

        Control$().minSize([0, 20])

        Label$()
          .text(state.finalScoreDisplay)
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
            "fontColor": Color(r: 1.0, g: 0.9, b: 0.3),
          ])

        Label$()
          .text(state.playTimeDisplay)
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
            "fontColor": Color(r: 0.7, g: 0.7, b: 0.7),
          ])

        Control$().minSize([0, 20])

        Label$()
          .text("Press SPACE to restart")
          .horizontalAlignment(.center)
          .theme(["fontSize": 16])
      }
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isVictory) { node, isVictory in
      node.visible = isVictory
    }
  }
}

// MARK: - Game Over Overlay

struct Chapter10GameOverOverlay: GView {
  let state: ObservableState<Chapter10GameViewState>

  var body: some GView {
    CenterContainer$ {
      VBoxContainer$ {
        Label$()
          .text("GAME OVER")
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 48,
            "fontColor": Color(r: 1.0, g: 0.3, b: 0.3),
          ])

        Control$().minSize([0, 20])

        Label$()
          .text(state.finalScoreDisplay)
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
            "fontColor": Color(r: 1.0, g: 0.9, b: 0.3),
          ])

        Label$()
          .text(state.playTimeDisplay)
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
            "fontColor": Color(r: 0.7, g: 0.7, b: 0.7),
          ])

        Control$().minSize([0, 20])

        Label$()
          .text("Press SPACE to restart")
          .horizontalAlignment(.center)
          .theme(["fontSize": 16])
      }
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isGameOver) { node, isGameOver in
      node.visible = isGameOver
    }
  }
}
