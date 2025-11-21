import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter2GameUI: GView {
  let gameState: State<Chapter2GameState>
  let playerHealth: State<Int>
  let maxHealth: Int

  var body: some GView {
    CanvasLayer$ {
      Chapter2TitleLabel()
      Chapter2HealthDisplay(health: playerHealth, maxHealth: maxHealth)
      Chapter2MenuOverlay(gameState: gameState)
      Chapter2VictoryOverlay(gameState: gameState)
      Chapter2GameOverOverlay(gameState: gameState)
    }
  }
}

struct Chapter2TitleLabel: GView {
  var body: some GView {
    Label$()
      .text("CHAPTER 2: COMBAT SYSTEM")
      .offsetLeft(20)
      .offsetTop(10)
  }
}

struct Chapter2HealthDisplay: GView {
  let health: State<Int>
  let maxHealth: Int

  var body: some GView {
    HBoxContainer$ {
      Label$().text("HP:")

      Label$()
        .bind(\.text, to: health) { h in
          (0 ..< maxHealth).map { i in i < h ? "♥" : "♡" }.joined(separator: " ")
        }
        .theme(["fontColor": Color(r: 1.0, g: 0.2, b: 0.2)])
    }
    .offsetLeft(20)
    .offsetTop(35)
  }
}

struct Chapter2MenuOverlay: GView {
  let gameState: State<Chapter2GameState>

  var body: some GView {
    CenterContainer$ {
      VBoxContainer$ {
        Label$()
          .text("SWIFT RUNNER")
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 32,
            "fontColor": Color(r: 0.3, g: 0.8, b: 1.0),
          ])

        Label$()
          .text("Press SPACE to start\nA/D or Arrow Keys to move\nSPACE/W/UP to jump\nX to attack\nReach the GREEN SQUARE to win!\nDefeat the RED ENEMIES!")
          .horizontalAlignment(.center)
          .theme(["fontSize": 8])
      }
    }
    .anchorsAndOffsets(.fullRect)
    .watch(gameState) { node, state in
      node.visible = state == .menu
    }
  }
}

struct Chapter2VictoryOverlay: GView {
  let gameState: State<Chapter2GameState>

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

        Control$().minSize([0, 10])

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

struct Chapter2GameOverOverlay: GView {
  let gameState: State<Chapter2GameState>

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

        Control$().minSize([0, 10])

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
