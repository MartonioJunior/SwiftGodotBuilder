import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter4GameUI: GView {
  let gameState: State<Chapter4GameState>
  let playerHealth: State<Int>
  let playerLives: State<Int>
  let score: State<Int>
  let playTime: State<Double>
  let maxHealth: Int
  let screenFlashAlpha: State<Float>

  var body: some GView {
    CanvasLayer$ {
      Chapter4HUD(
        health: playerHealth,
        lives: playerLives,
        score: score,
        playTime: playTime,
        maxHealth: maxHealth,
        gameState: gameState
      )
      Chapter4MenuOverlay(gameState: gameState)
      Chapter4VictoryOverlay(gameState: gameState, score: score, playTime: playTime)
      Chapter4GameOverOverlay(gameState: gameState, score: score, playTime: playTime)

      // Screen flash effect
      ColorRect$()
        .color(Color(r: 1, g: 1, b: 1))
        .anchorsAndOffsets(.fullRect)
        .watch(screenFlashAlpha) { node, alpha in
          node.modulate = Color(r: 1, g: 1, b: 1, a: alpha)
          node.visible = alpha > 0
        }
    }
  }
}

// MARK: - HUD (In-Game UI)

struct Chapter4HUD: GView {
  let health: State<Int>
  let lives: State<Int>
  let score: State<Int>
  let playTime: State<Double>
  let maxHealth: Int
  let gameState: State<Chapter4GameState>

  var body: some GView {
    // Top HUD bar with proper layout
    VBoxContainer$ {
      // Title
      Label$()
        .text("CHAPTER 4: CAMERA & SCREEN EFFECTS")
        .horizontalAlignment(.center)
        .theme([
          "fontColor": Color(r: 1.0, g: 1.0, b: 1.0, a: 0.9),
        ])

      // Stats row
      HBoxContainer$ {
        // Health hearts
        Label$().text("HP:")
        Label$()
          .bind(\.text, to: health) { h in
            (0 ..< maxHealth).map { i in i < h ? "♥" : "♡" }.joined(separator: " ")
          }
          .theme(["fontColor": Color(r: 1.0, g: 0.2, b: 0.2)])

        Control$().sizeH(.expandFill)

        // Lives
        Label$()
          .bind(\.text, to: lives) { l in
            "Lives: \(l)"
          }
          .theme(["fontColor": Color(r: 0.3, g: 0.8, b: 1.0)])

        Control$().sizeH(.expandFill)

        // Score
        Label$()
          .bind(\.text, to: score) { s in
            "Score: \(s)"
          }
          .theme(["fontColor": Color(r: 1.0, g: 0.9, b: 0.3)])

        Control$().sizeH(.expandFill)

        // Timer
        Label$()
          .bind(\.text, to: playTime) { t in
            String(format: "Time: %.1fs", t)
          }
          .theme(["fontColor": Color(r: 0.7, g: 0.7, b: 0.7)])
      }
      .sizeH(.expandFill)
    }
    .anchors(.topWide)
    .offset(top: 0, right: -10, bottom: 0, left: 10)
    .watch(gameState) { node, state in
      node.visible = state == .playing
    }
    // .theme(["separation": 20])
  }
}

// MARK: - Menu Overlay

struct Chapter4MenuOverlay: GView {
  let gameState: State<Chapter4GameState>

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 4")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 32,
              "fontColor": Color(r: 0.3, g: 0.8, b: 1.0),
            ])

          Label$()
            .text("CAMERA & SCREEN EFFECTS")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 16,
              "fontColor": Color(r: 0.7, g: 0.7, b: 0.7),
            ])

          Control$().minSize([0, 20])

          Label$()
            .text("Features:")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 16,
              "fontColor": Color(r: 1.0, g: 1.0, b: 1.0),
            ])

          Label$()
            .text("• Camera2D Following Player\n• Screen Shake on Hits\n• Hit Pause/Freeze Frames\n• Screen Flash Effects")
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
    .watch(gameState) { node, state in
      node.visible = state == .menu
    }
  }
}

// MARK: - Victory Overlay

struct Chapter4VictoryOverlay: GView {
  let gameState: State<Chapter4GameState>
  let score: State<Int>
  let playTime: State<Double>

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
          .bind(\.text, to: score) { s in
            "Final Score: \(s)"
          }
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
            "fontColor": Color(r: 1.0, g: 0.9, b: 0.3),
          ])

        Label$()
          .bind(\.text, to: playTime) { t in
            String(format: "Time: %.1fs", t)
          }
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
    .watch(gameState) { node, state in
      node.visible = state == .victory
    }
  }
}

// MARK: - Game Over Overlay

struct Chapter4GameOverOverlay: GView {
  let gameState: State<Chapter4GameState>
  let score: State<Int>
  let playTime: State<Double>

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
          .bind(\.text, to: score) { s in
            "Final Score: \(s)"
          }
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
            "fontColor": Color(r: 1.0, g: 0.9, b: 0.3),
          ])

        Label$()
          .bind(\.text, to: playTime) { t in
            String(format: "Time: %.1fs", t)
          }
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
    .watch(gameState) { node, state in
      node.visible = state == .gameOver
    }
  }
}
