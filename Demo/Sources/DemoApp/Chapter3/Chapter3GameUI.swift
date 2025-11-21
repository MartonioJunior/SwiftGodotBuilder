import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter3GameUI: GView {
  let gameState: State<Chapter3GameState>
  let playerHealth: State<Int>
  let playerLives: State<Int>
  let score: State<Int>
  let playTime: State<Double>
  let maxHealth: Int

  var body: some GView {
    CanvasLayer$ {
      Chapter3HUD(
        health: playerHealth,
        lives: playerLives,
        score: score,
        playTime: playTime,
        maxHealth: maxHealth,
        gameState: gameState
      )
      Chapter3MenuOverlay(gameState: gameState)
      Chapter3VictoryOverlay(gameState: gameState, score: score, playTime: playTime)
      Chapter3GameOverOverlay(gameState: gameState, score: score, playTime: playTime)
    }
  }
}

// MARK: - HUD (In-Game UI)

struct Chapter3HUD: GView {
  let health: State<Int>
  let lives: State<Int>
  let score: State<Int>
  let playTime: State<Double>
  let maxHealth: Int
  let gameState: State<Chapter3GameState>

  var body: some GView {
    // Top HUD bar with proper layout
    VBoxContainer$ {
      // Title
      Label$()
        .text("CHAPTER 3: HUD & UI BASICS")
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

struct Chapter3MenuOverlay: GView {
  let gameState: State<Chapter3GameState>

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 3")
            .horizontalAlignment(.center)
            .theme([
              "fontSize": 32,
              "fontColor": Color(r: 0.3, g: 0.8, b: 1.0),
            ])

          Label$()
            .text("HUD & UI BASICS")
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
            .text("• Lives System (3 lives)\n• Score Tracking\n• Game Timer\n• Professional HUD Layout")
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

struct Chapter3VictoryOverlay: GView {
  let gameState: State<Chapter3GameState>
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

struct Chapter3GameOverOverlay: GView {
  let gameState: State<Chapter3GameState>
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
