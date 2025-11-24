import SwiftGodot
import SwiftGodotBuilder

struct Chapter14GameUI: GView {
  let state: ObservableState<Chapter14GameViewState>
  let settings: ObservableState<GameSettings>

  let palette = Chapter14Palette()

  var body: some GView {
    CanvasLayer$ {
      Chapter14HUD(state: state)
      Chapter14MenuOverlay(state: state)
      Chapter14PauseOverlay(state: state)
      Chapter14SettingsOverlay(state: state, settings: settings)
      Chapter14CharacterOverlay(state: state)
      Chapter14VictoryOverlay(state: state)
      Chapter14GameOverOverlay(state: state)

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
    .onProcess { [state] _, _ in
      // Handle pause toggle
      if Action("pause").isJustPressed {
        switch state.wrappedValue.gameState {
        case .playing:
          state.wrappedValue.pauseGame()
        case .paused:
          state.wrappedValue.resumeGame()
        case .settings:
          // ESC closes settings and returns to paused state
          state.wrappedValue.gameState = .paused
        default:
          break
        }
      }
    }
  }
}

// MARK: - HUD (In-Game UI)

struct Chapter14HUD: GView {
  let state: ObservableState<Chapter14GameViewState>

  let palette = Chapter14Palette()

  var body: some GView {
    VBoxContainer$ {
      // Title
      Label$()
        .text("CHAPTER 14: SETTINGS & AUDIO CONTROLS")
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

struct Chapter14MenuOverlay: GView {
  let state: ObservableState<Chapter14GameViewState>

  let palette = Chapter14Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 14")
            .horizontalAlignment(.center)
            .theme(["fontSize": 32, "fontColor": palette.cyan])

          Label$()
            .text("SETTINGS & AUDIO CONTROLS")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.gray])

          Label$()
            .text("New Features:")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.white])

          Label$()
            .text("• Settings Menu (from Main & Pause)\n• Master/Music/SFX Volume Sliders\n• Fullscreen Toggle\n• Control Remapping")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.lightGray])

          Label$()
            .text("Press SPACE to start")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.yellowBright])

          Button$()
            .text("Settings")
            .minSize([150, 0])
            .normalStyle(
              StyleBoxFlat$()
                .bgColor(palette.gray.withAlpha(0.2))
                .borderColor(palette.lightGray)
                .borderWidth(2)
                .cornerRadius(4)
            )
            .hoverStyle(
              StyleBoxFlat$()
                .bgColor(palette.cyan.withAlpha(0.3))
                .borderColor(palette.cyan)
                .borderWidth(2)
                .cornerRadius(4)
            )
            .pressedStyle(
              StyleBoxFlat$()
                .bgColor(palette.cyan.withAlpha(0.5))
                .borderColor(palette.cyan)
                .borderWidth(2)
                .cornerRadius(4)
            )
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.gameState = .settings
            }

          Label$()
            .text("Q = Switch  |  SHIFT = Dash | ESC = Pause  |  TAB = Character Sheet")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.darkGray])
        }
        .theme(["separation": 3])
      }
      .panelStyle(
        StyleBoxFlat$()
          .bgColor(Color(r: 0.05, g: 0.05, b: 0.1, a: 0.95))
          .borderColor(palette.cyan)
          .borderWidth(2)
          .contentMargin(2)
          .expandMargin(4)
          .cornerRadius(8)
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isMenu) { node, isMenu in
      node.visible = isMenu
    }
  }
}

// MARK: - Victory Overlay

struct Chapter14VictoryOverlay: GView {
  let state: ObservableState<Chapter14GameViewState>

  let palette = Chapter14Palette()

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
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isVictory) { node, isVictory in
      node.visible = isVictory
    }
  }
}

// MARK: - Game Over Overlay

struct Chapter14GameOverOverlay: GView {
  let state: ObservableState<Chapter14GameViewState>

  let palette = Chapter14Palette()

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
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isGameOver) { node, isGameOver in
      node.visible = isGameOver
    }
  }
}

// MARK: - Pause Overlay

struct Chapter14PauseOverlay: GView {
  let state: ObservableState<Chapter14GameViewState>

  let palette = Chapter14Palette()

  var body: some GView {
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
            .text("Settings")
            .minSize([200, 0])
            .normalStyle(
              StyleBoxFlat$()
                .bgColor(palette.purple.withAlpha(0.2))
                .borderColor(palette.purple)
                .borderWidth(2)
                .cornerRadius(4)
            )
            .hoverStyle(
              StyleBoxFlat$()
                .bgColor(palette.purple.withAlpha(0.4))
                .borderColor(palette.purple)
                .borderWidth(2)
                .cornerRadius(4)
            )
            .pressedStyle(
              StyleBoxFlat$()
                .bgColor(palette.purple.withAlpha(0.6))
                .borderColor(palette.purple)
                .borderWidth(2)
                .cornerRadius(4)
            )
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.gameState = .settings
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
          .expandMargin(2)
          .contentMargin(2)
          .cornerRadius(8)
      )
    }
    .anchorsAndOffsets(.fullRect)
    .watch(state, \.isPaused) { node, isPaused in
      node.visible = isPaused
    }
  }
}

// MARK: - Settings Overlay

struct Chapter14SettingsOverlay: GView {
  let state: ObservableState<Chapter14GameViewState>
  let settings: ObservableState<GameSettings>
  @State var previousGameState: Chapter14GameState = .menu

  let palette = Chapter14Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        MarginContainer$ {
          VBoxContainer$ {
            Label$()
              .text("SETTINGS")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.purple])

            HBoxContainer$ {
              VBoxContainer$ {
                // Audio Section
                Label$()
                  .text("AUDIO")
                  .horizontalAlignment(.left)
                  .theme(["fontColor": palette.white])

                // Master Volume
                HBoxContainer$ {
                  Label$()
                    .text("Master")
                    .minSize([45, 0])
                    .theme(["fontColor": palette.lightGray])

                  HSlider$()
                    .minValue(0)
                    .maxValue(1)
                    .step(0.01)
                    .value(settings.masterVolume)
                    .minSize([100, 0])

                  Label$()
                    .text(settings.masterVolumeDisplay)
                    .minSize([35, 0])
                    .theme(["fontColor": palette.cyan])
                }

                // Music Volume
                HBoxContainer$ {
                  Label$()
                    .text("Music")
                    .minSize([45, 0])
                    .theme(["fontColor": palette.lightGray])

                  HSlider$()
                    .minValue(0)
                    .maxValue(1)
                    .step(0.01)
                    .value(settings.musicVolume)
                    .minSize([100, 0])

                  Label$()
                    .text(settings.musicVolumeDisplay)
                    .minSize([35, 0])
                    .theme(["fontColor": palette.cyan])
                }

                // SFX Volume
                HBoxContainer$ {
                  Label$()
                    .text("SFX")
                    .minSize([45, 0])
                    .theme(["fontColor": palette.lightGray])

                  HSlider$()
                    .minValue(0)
                    .maxValue(1)
                    .step(0.01)
                    .value(settings.sfxVolume)
                    .minSize([100, 0])

                  Label$()
                    .text(settings.sfxVolumeDisplay)
                    .minSize([35, 0])
                    .theme(["fontColor": palette.cyan])
                }
              }

              VBoxContainer$ {
                // Display Section
                Label$()
                  .text("DISPLAY")
                  .horizontalAlignment(.left)
                  .theme(["fontColor": palette.white])

                // Fullscreen Toggle
                HBoxContainer$ {
                  Label$()
                    .text("Fullscreen")
                    .minSize([70, 0])
                    .theme(["fontColor": palette.lightGray])

                  CheckButton$()
                    .pressed(settings.fullscreen)
                    .onSignal(\.toggled) { [settings] _, isFullscreen in
                      // Apply fullscreen setting when toggled
                      DisplayServer.windowSetMode(isFullscreen ? .fullscreen : .windowed)
                      // Save settings
                      settings.wrappedValue.savePersistence()
                    }
                }
              }
            }

            // Action Buttons
            HBoxContainer$ {
              Button$()
                .text("Reset")
                .minSize([70, 0])
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
                )
                .pressedStyle(
                  StyleBoxFlat$()
                    .bgColor(palette.yellow.withAlpha(0.6))
                    .borderColor(palette.yellowBright)
                    .borderWidth(2)
                    .cornerRadius(4)
                )
                .onSignal(\.pressed) { [settings] _ in
                  settings.wrappedValue.resetToDefaults()
                }

              Button$()
                .text("Save")
                .minSize([70, 0])
                .normalStyle(
                  StyleBoxFlat$()
                    .bgColor(palette.green.withAlpha(0.3))
                    .borderColor(palette.green)
                    .borderWidth(2)
                    .cornerRadius(4)
                )
                .hoverStyle(
                  StyleBoxFlat$()
                    .bgColor(palette.green.withAlpha(0.5))
                    .borderColor(palette.green)
                    .borderWidth(2)
                    .cornerRadius(4)
                )
                .pressedStyle(
                  StyleBoxFlat$()
                    .bgColor(palette.green.withAlpha(0.7))
                    .borderColor(palette.green)
                    .borderWidth(2)
                    .cornerRadius(4)
                )
                .onSignal(\.pressed) { [settings] _ in
                  settings.wrappedValue.savePersistence()
                }

              Control$().sizeH(.expandFill)

              Button$()
                .text("Back")
                .minSize([70, 0])
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
                )
                .pressedStyle(
                  StyleBoxFlat$()
                    .bgColor(palette.cyan.withAlpha(0.7))
                    .borderColor(palette.cyan)
                    .borderWidth(2)
                    .cornerRadius(4)
                )
                .onSignal(\.pressed) { [state, previousGameState] _ in
                  // Go back to previous state (menu or paused)
                  state.wrappedValue.gameState = previousGameState
                }
            }
          }
          .theme(["separation": 2])
        }
        .theme(["marginTop": 4, "marginRight": 4, "marginBottom": 4, "marginLeft": 4])
      }
      // Settings panel styling
      .panelStyle(
        StyleBoxFlat$()
          .bgColor(Color(r: 0.08, g: 0.08, b: 0.12, a: 0.98))
          .borderColor(palette.purple)
          .borderWidth(2)
          .expandMargin(-2)
          .cornerRadius(4)
      )
    }
    // .anchorsAndOffsets(.fullRect)
    .watch(state, \.isSettings) { node, isSettings in
      node.visible = isSettings
    }
  }
}

// MARK: - Character/Inventory Overlay

struct Chapter14CharacterOverlay: GView {
  let state: ObservableState<Chapter14GameViewState>
  @State var showOverlay: Bool = false

  let palette = Chapter14Palette()

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
