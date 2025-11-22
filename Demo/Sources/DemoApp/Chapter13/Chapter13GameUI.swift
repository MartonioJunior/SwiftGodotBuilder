import SwiftGodot
import SwiftGodotBuilder

struct Chapter13GameUI: GView {
  let state: ObservableState<Chapter13GameViewState>

  let palette = Palette()

  var body: some GView {
    CanvasLayer$ {
      Chapter13HUD(state: state)
      Chapter13MenuOverlay(state: state)
      Chapter13PauseOverlay(state: state)
      Chapter13CharacterOverlay(state: state)
      Chapter13VictoryOverlay(state: state)
      Chapter13GameOverOverlay(state: state)

      // Screen flash effect
      ColorRect$()
        .color(palette.white)
        .anchorsAndOffsets(.fullRect)
        .watch(state, \.screenFlashAlpha) { node, alpha in
          let c = palette.white
          node.modulate = Color(r: c.red, g: c.green, b: c.blue, a: alpha)
          node.visible = alpha > 0
        }
    }
    .processMode(.always)
  }
}

// MARK: - HUD (In-Game UI)

struct Chapter13HUD: GView {
  let state: ObservableState<Chapter13GameViewState>

  let palette = Palette()

  var body: some GView {
    VBoxContainer$ {
      // Title
      Label$()
        .text("CHAPTER 13: PAUSING, UI & STYLING")
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
    .watch(state, \.isPlaying) { node, isPlaying in
      node.visible = isPlaying
    }
  }
}

// MARK: - Menu Overlay

struct Chapter13MenuOverlay: GView {
  let state: ObservableState<Chapter13GameViewState>

  let palette = Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 13")
            .horizontalAlignment(.center)
            .theme(["fontSize": 32, "fontColor": palette.cyan])

          Label$()
            .text("PAUSING, UI & STYLING")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.gray])

          Label$()
            .text("New Features:")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.white])

          Label$()
            .text("• Pause Menu (ESC)\n• Character/Inventory Overlay (TAB)\n• StyleBox$ Declarative Styling\n• Rounded Corners, Borders & Shadows")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.lightGray])

          Label$()
            .text("Press SPACE to start")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.yellowBright])

          Label$()
            .text("Q = Switch  |  SHIFT = Dash | ESC = Pause  |  TAB = Character Sheet")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.darkGray])
        }
        .theme(["separation": 3])
      }
      // Styled panel with shadow and rounded corners
      .panelStyle(
        StyleBoxFlat$()
          .bgColor(Color(r: 0.05, g: 0.05, b: 0.1, a: 0.95))
          .borderColor(palette.cyan)
          .borderWidth(2)
          .cornerRadius(8)
          .shadowColor(palette.cyan.withAlpha(0.5))
          .shadowSize(8)
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isMenu) { node, isMenu in
      node.visible = isMenu
    }
  }
}

// MARK: - Victory Overlay

struct Chapter13VictoryOverlay: GView {
  let state: ObservableState<Chapter13GameViewState>

  let palette = Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("YOU WIN!")
            .horizontalAlignment(.center)
            .theme(["fontSize": 48, "fontColor": palette.green])

          Label$()
            .text(state.finalScoreDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.yellow])

          Label$()
            .text(state.playTimeDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.gray])

          Label$()
            .text("Press SPACE to restart")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16])
        }
        .theme(["separation": 4])
      }
      // Victory panel with green glow
      .panelStyle(
        StyleBoxFlat$()
          .bgColor(Color(r: 0.05, g: 0.15, b: 0.05, a: 0.95))
          .borderColor(palette.green)
          .borderWidth(3)
          .cornerRadius(12)
          .shadowColor(palette.green.withAlpha(0.6))
          .shadowSize(4)
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isVictory) { node, isVictory in
      node.visible = isVictory
    }
  }
}

// MARK: - Game Over Overlay

struct Chapter13GameOverOverlay: GView {
  let state: ObservableState<Chapter13GameViewState>

  let palette = Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("GAME OVER")
            .horizontalAlignment(.center)
            .theme(["fontSize": 48, "fontColor": palette.redLight])

          Label$()
            .text(state.finalScoreDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.yellow])

          Label$()
            .text(state.playTimeDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.gray])

          Label$()
            .text("Press SPACE to restart")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16])
        }
        .theme(["separation": 4])
      }
      // Game over panel with red glow
      .panelStyle(
        StyleBoxFlat$()
          .bgColor(Color(r: 0.15, g: 0.05, b: 0.05, a: 0.95))
          .borderColor(palette.redLight)
          .borderWidth(3)
          .cornerRadius(12)
          .shadowColor(palette.redLight.withAlpha(0.6))
          .shadowSize(4)
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isGameOver) { node, isGameOver in
      node.visible = isGameOver
    }
  }
}

// MARK: - Pause Overlay

struct Chapter13PauseOverlay: GView {
  let state: ObservableState<Chapter13GameViewState>

  let palette = Palette()

  var body: some GView {
    Node2D$ {
      // Semi-transparent dark background
      ColorRect$()
        .color(Color(r: 0, g: 0, b: 0, a: 0.7))
        .anchorsAndOffsets(.fullRect)
        .watch(state, \.isPaused) { node, isPaused in
          node.visible = isPaused
        }

      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            Label$()
              .text("PAUSED")
              .horizontalAlignment(.center)
              .theme(["fontSize": 32, "fontColor": palette.white])

            // Styled buttons demonstrating hover/pressed states
            Button$()
              .text("Resume (ESC)")
              .minSize([200, 0])
              .normalStyle(
                StyleBoxFlat$()
                  .bgColor(palette.cyan.withAlpha(0.3))
                  .borderColor(palette.cyan)
                  .borderWidth(2)
                  .cornerRadius(4)
              )
              .hoverStyle(
                StyleBoxFlat$()
                  .bgColor(palette.cyan.withAlpha(0.5))
                  .borderColor(palette.cyan)
                  .borderWidth(2)
                  .cornerRadius(4)
                  .shadowColor(palette.cyan.withAlpha(0.4))
                  .shadowSize(4)
              )
              .pressedStyle(
                StyleBoxFlat$()
                  .bgColor(palette.cyan.withAlpha(0.7))
                  .borderColor(palette.cyan)
                  .borderWidth(2)
                  .cornerRadius(4)
              )
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.resumeGame()
              }

            Button$()
              .text("Restart")
              .minSize([200, 0])
              .normalStyle(
                StyleBoxFlat$()
                  .bgColor(palette.yellow.withAlpha(0.2))
                  .borderColor(palette.yellow)
                  .borderWidth(2)
                  .cornerRadius(4)
              )
              .hoverStyle(
                StyleBoxFlat$()
                  .bgColor(palette.yellow.withAlpha(0.4))
                  .borderColor(palette.yellowBright)
                  .borderWidth(2)
                  .cornerRadius(4)
                  .shadowColor(palette.yellow.withAlpha(0.3))
                  .shadowSize(4)
              )
              .pressedStyle(
                StyleBoxFlat$()
                  .bgColor(palette.yellow.withAlpha(0.6))
                  .borderColor(palette.yellowBright)
                  .borderWidth(2)
                  .cornerRadius(4)
              )
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.reset()
                Engine.onNextFrame {
                  state.wrappedValue.gameState = .playing
                }
              }

            Button$()
              .text("Quit to Menu")
              .minSize([200, 0])
              .normalStyle(
                StyleBoxFlat$()
                  .bgColor(palette.gray.withAlpha(0.2))
                  .borderColor(palette.gray)
                  .borderWidth(2)
                  .cornerRadius(4)
              )
              .hoverStyle(
                StyleBoxFlat$()
                  .bgColor(palette.lightGray.withAlpha(0.3))
                  .borderColor(palette.lightGray)
                  .borderWidth(2)
                  .cornerRadius(4)
                  .shadowColor(palette.gray.withAlpha(0.3))
                  .shadowSize(4)
              )
              .pressedStyle(
                StyleBoxFlat$()
                  .bgColor(palette.darkGray.withAlpha(0.5))
                  .borderColor(palette.lightGray)
                  .borderWidth(2)
                  .cornerRadius(4)
              )
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.gameState = .menu
              }
          }
          .theme(["separation": 4])
        }
        // Pause panel styling
        .panelStyle(
          StyleBoxFlat$()
            .bgColor(Color(r: 0.1, g: 0.1, b: 0.15, a: 0.98))
            .borderColor(palette.white.withAlpha(0.5))
            .borderWidth(2)
            .cornerRadius(8)
            .shadowColor(Color(r: 0, g: 0, b: 0, a: 0.8))
            .shadowSize(16)
        )
      }
      .anchorsAndOffsets(.fullRect)
      .watch(state, \.isPaused) { node, isPaused in
        node.visible = isPaused
      }
    }
  }
}

// MARK: - Character/Inventory Overlay

struct Chapter13CharacterOverlay: GView {
  let state: ObservableState<Chapter13GameViewState>
  @State var showOverlay: Bool = false

  let palette = Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHARACTER SHEET")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.cyan])

          HBoxContainer$ {
            // Health section with styled background
            PanelContainer$ {
              VBoxContainer$ {
                Label$()
                  .text("HEALTH")
                  .horizontalAlignment(.center)
                  .theme(["fontColor": palette.healthHeader])

                Label$()
                  .text(state.healthDisplay)
                  .horizontalAlignment(.center)
                  .theme(["fontSize": 16, "fontColor": palette.red])
              }
              .theme(["separation": 2])
            }
            .panelStyle(
              StyleBoxFlat$()
                .bgColor(palette.red.withAlpha(0.1))
                .borderColor(palette.red.withAlpha(0.4))
                .borderWidth(1)
                .cornerRadius(4)
                .contentMargin(4)
            )

            // Inventory section with styled background
            PanelContainer$ {
              VBoxContainer$ {
                Label$()
                  .text("INVENTORY")
                  .horizontalAlignment(.center)
                  .theme(["fontColor": palette.yellowBright])

                Label$()
                  .text(state.coinsDisplay)
                  .horizontalAlignment(.center)
                  .theme(["fontSize": 16, "fontColor": palette.yellow])

                Label$()
                  .text("🔑")
                  .horizontalAlignment(.center)
                  .visible(state.hasKey)
                  .theme(["fontColor": palette.gold])
              }
              .theme(["separation": 2])
            }
            .panelStyle(
              StyleBoxFlat$()
                .bgColor(palette.yellow.withAlpha(0.1))
                .borderColor(palette.yellow.withAlpha(0.4))
                .borderWidth(1)
                .cornerRadius(4)
                .contentMargin(4)
            )

            // Weapon section with styled background
            PanelContainer$ {
              VBoxContainer$ {
                Label$()
                  .text("WEAPONS")
                  .horizontalAlignment(.center)
                  .theme(["fontColor": palette.weaponHeader])

                Label$()
                  .text(state.weaponDisplay)
                  .horizontalAlignment(.center)
                  .theme(["fontSize": 16, "fontColor": palette.lightGray])

                Label$()
                  .text(state.ammoDisplay)
                  .horizontalAlignment(.center)
                  .theme(["fontColor": palette.cyan])
              }
              .theme(["separation": 2])
            }
            .panelStyle(
              StyleBoxFlat$()
                .bgColor(palette.cyan.withAlpha(0.1))
                .borderColor(palette.cyan.withAlpha(0.4))
                .borderWidth(1)
                .cornerRadius(4)
                .contentMargin(4)
            )

            // Stats section with styled background
            PanelContainer$ {
              VBoxContainer$ {
                Label$()
                  .text("STATS")
                  .horizontalAlignment(.center)
                  .theme(["fontColor": palette.greenLight])

                Label$()
                  .text(state.scoreDisplay)
                  .horizontalAlignment(.center)
                  .theme(["fontSize": 16, "fontColor": palette.greenLight])

                Label$()
                  .text(state.livesDisplay)
                  .horizontalAlignment(.center)
                  .theme(["fontColor": palette.lightGray])
              }
              .theme(["separation": 2])
            }
            .panelStyle(
              StyleBoxFlat$()
                .bgColor(palette.green.withAlpha(0.1))
                .borderColor(palette.green.withAlpha(0.4))
                .borderWidth(1)
                .cornerRadius(4)
                .contentMargin(4)
            )
          }
          .theme(["separation": 4])
        }
        .theme(["separation": 8])
      }
      // Main character sheet panel
      .panelStyle(
        StyleBoxFlat$()
          .bgColor(Color(r: 0.05, g: 0.08, b: 0.12, a: 0.98))
          .borderColor(palette.cyan)
          .borderWidth(3)
          .cornerRadius(8)
          .shadowColor(palette.cyan.withAlpha(0.4))
          .shadowSize(4)
          .contentMargin(8)
      )
    }
    .anchorsAndOffsets(.fullRect)
    .visible($showOverlay)
    .onProcess { _, _ in
      if Action("character_sheet").isJustPressed {
        showOverlay.toggle()
      }
    }
  }
}
