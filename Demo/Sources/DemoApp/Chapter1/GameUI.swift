import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter1GameUI: GView {
  let gameState: State<Chapter1GameState>

  var body: some GView {
    CanvasLayer$ {
      Chapter1TitleLabel()
      Chapter1MenuOverlay(gameState: gameState)
      Chapter1VictoryOverlay(gameState: gameState)
    }
  }
}

struct Chapter1TitleLabel: GView {
  var body: some GView {
    Label$()
      .text("CHAPTER 1: YOUR FIRST PLATFORMER")
      .offsetLeft(20)
      .offsetTop(10)
  }
}

struct Chapter1MenuOverlay: GView {
  let gameState: State<Chapter1GameState>

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
          .text("Press SPACE to start\nA/D or Arrow Keys to move\nSPACE/W/UP to jump\nReach the GREEN SQUARE to win!\nAvoid the RED ENEMY!")
          .horizontalAlignment(.center)
          .theme([
            "fontSize": 16,
          ])
      }
    }
    .anchorsAndOffsets(.fullRect)
    .bind(\.visible, to: gameState) { (state: Chapter1GameState) in state == .menu }
  }
}

struct Chapter1VictoryOverlay: GView {
  let gameState: State<Chapter1GameState>

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
          .theme([
            "fontSize": 16,
          ])
      }
    }
    .anchorsAndOffsets(.fullRect)
    .bind(\.visible, to: gameState) { (state: Chapter1GameState) in state == .victory }
  }
}
