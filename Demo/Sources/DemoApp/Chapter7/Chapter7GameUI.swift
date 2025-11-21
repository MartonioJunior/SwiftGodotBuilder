import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter7GameUI: GView {
  let state: ObservableState<Chapter7GameViewState>

  var body: some GView {
    CanvasLayer$ {
      Chapter7HUD(state: state)
      Chapter7MenuOverlay(state: state)
      Chapter7VictoryOverlay(state: state)
      Chapter7GameOverOverlay(state: state)

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

struct Chapter7HUD: GView {
  let state: ObservableState<Chapter7GameViewState>

  var body: some GView {
    // Top HUD bar with proper layout
    VBoxContainer$ {
      // Title
      Label$()
        .text("CHAPTER 7: AUDIO & EVENT ARCHITECTURE")
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

        // Lives
        Label$()
          .text(state.livesDisplay)
          .theme(["fontColor": Color(r: 0.3, g: 0.8, b: 1.0)])

        Control$().sizeH(.expandFill)

        // Score
        Label$()
          .text(state.scoreDisplay)
          .theme(["fontColor": Color(r: 1.0, g: 0.9, b: 0.3)])

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

struct Chapter7MenuOverlay: GView {
  let state: ObservableState<Chapter7GameViewState>

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 7")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 32,
              "fontColor": Color(r: 0.3, g: 0.8, b: 1.0),
            ])

          Label$()
            .text("BFXR AUDIO & SEMANTIC EVENTS")
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
            .text("• Real-time Bfxr Synthesizer\n• Polyphonic Audio Playback\n• Semantic Event Architecture\n• Event-Driven Particles & VFX")
            .horizontalAlignment(.center)
            .theme(["fontColor": Color(r: 0.9, g: 0.9, b: 0.9)])

          Control$().minSize([0, 20])

          Label$()
            .text("Press SPACE to start")
            .horizontalAlignment(.center)
            .theme(["fontColor": Color(r: 1.0, g: 1.0, b: 0.5)])

          Control$().minSize([0, 10])

          Label$()
            .text("A/D or Arrows = Move  |  SPACE/W/UP = Jump  |  X = Attack")
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

struct Chapter7VictoryOverlay: GView {
  let state: ObservableState<Chapter7GameViewState>

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

struct Chapter7GameOverOverlay: GView {
  let state: ObservableState<Chapter7GameViewState>

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
