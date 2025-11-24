import SwiftGodot
import SwiftGodotBuilder

struct Chapter15GameUI: GView {
  let state: ObservableState<Chapter15GameViewState>
  let settings: ObservableState<Chapter15GameSettings>
  let progress: ObservableState<GameProgress>

  let palette = Chapter15Palette()

  var body: some GView {
    CanvasLayer$ {
      Chapter15HUD(state: state)
      Chapter15LevelSelectOverlay(state: state, progress: progress)
      Chapter15PauseOverlay(state: state)
      Chapter15SettingsOverlay(state: state, settings: settings, progress: progress)
      Chapter15CharacterOverlay(state: state)
      Chapter15LevelCompleteOverlay(state: state, progress: progress)
      Chapter15GameOverOverlay(state: state)

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

// MARK: - Level Complete Overlay

struct Chapter15LevelCompleteOverlay: GView {
  let state: ObservableState<Chapter15GameViewState>
  let progress: ObservableState<GameProgress>

  let palette = Chapter15Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("LEVEL COMPLETE!")
            .horizontalAlignment(.center)
            .theme(["fontSize": 48, "fontColor": palette.green])

          // Level info
          Label$()
            .text(levelNameDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.cyan])

          Control$().minSize([0, 8])

          // Stats
          Label$()
            .text(state.coinsDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.yellow])

          Label$()
            .text(state.playTimeDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.gray])

          Label$()
            .text(state.finalScoreDisplay)
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.white])

          Control$().minSize([0, 8])

          // Buttons
          HBoxContainer$ {
            Button$()
              .text("Next Level")
              .minSize([120, 0])
              .disabled(!hasNextLevel)
              .styleBoxes(palette.greenButtonStyles)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.nextLevel()
              }

            Control$().sizeH(.expandFill).minSize([8, 0])

            Button$()
              .text("Retry")
              .minSize([120, 0])
              .styleBoxes(palette.cyanButtonStyles)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.restartLevel()
              }

            Control$().sizeH(.expandFill).minSize([8, 0])

            Button$()
              .text("Level Select")
              .minSize([120, 0])
              .styleBoxes(palette.grayButtonStyles)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.returnToLevelSelect()
              }
          }
        }
        .theme(["separation": 4])
      }
      .styleBox("panel", palette.victoryPanelStyle)
    }
    .anchorsAndOffsets(.fullRect)
    .visible(state.isLevelComplete)
  }

  var levelNameDisplay: String {
    if let levelData = Chapter15.getLevelData(state.wrappedValue.currentLevelId) {
      return levelData.name
    }
    return "Level \(state.wrappedValue.currentLevelId)"
  }

  var hasNextLevel: Bool {
    Chapter15.getLevelData(state.wrappedValue.currentLevelId + 1) != nil
  }
}

// MARK: - Game Over Overlay

struct Chapter15GameOverOverlay: GView {
  let state: ObservableState<Chapter15GameViewState>

  let palette = Chapter15Palette()

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
      .styleBox("panel", palette.gameOverPanelStyle)
    }
    .anchorsAndOffsets(.fullRect)
    .visible(state.isGameOver)
  }
}

// MARK: - Pause Overlay

struct Chapter15PauseOverlay: GView {
  let state: ObservableState<Chapter15GameViewState>

  let palette = Chapter15Palette()

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
            .styleBoxes(palette.cyanButtonStylesEnhanced)
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.resumeGame()
            }

          Button$()
            .text("Restart")
            .minSize([200, 0])
            .styleBoxes(palette.yellowButtonStyles)
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.reset()
              Engine.onNextFrame {
                state.wrappedValue.gameState = .playing
              }
            }

          Button$()
            .text("Settings")
            .minSize([200, 0])
            .styleBoxes(palette.purpleButtonStyles)
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.gameState = .settings
            }

          Button$()
            .text("Quit to Menu")
            .minSize([200, 0])
            .styleBoxes(palette.grayButtonStylesWithLightHover)
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.gameState = .levelSelect
            }
        }
        .theme(["separation": 4])
      }
      .styleBox("panel", palette.pausePanelStyle)
    }
    .anchorsAndOffsets(.fullRect)
    .visible(state.isPaused)
  }
}

// MARK: - Settings Overlay

struct Chapter15SettingsOverlay: GView {
  let state: ObservableState<Chapter15GameViewState>
  let settings: ObservableState<Chapter15GameSettings>
  let progress: ObservableState<GameProgress>
  @State var previousGameState: Chapter15GameState = .levelSelect

  let palette = Chapter15Palette()

  var settingsButtons: some GView {
    HBoxContainer$ {
      Button$()
        .text("Reset")
        .minSize([70, 0])
        .styleBoxes(palette.yellowButtonStyles)
        .onSignal(\.pressed) { [settings] _ in
          settings.wrappedValue.resetToDefaults()
        }

      Button$()
        .text("Save")
        .minSize([70, 0])
        .styleBoxes(palette.greenButtonStylesEnhanced)
        .onSignal(\.pressed) { [settings] _ in
          settings.wrappedValue.savePersistence()
        }

      Control$().sizeH(.expandFill)

      Button$()
        .text("Clear Progress")
        .minSize([100, 0])
        .styleBoxes(palette.purpleButtonStyles)
        .onSignal(\.pressed) { [progress] _ in
          GD.print("🗑️ Clearing progress...")
          progress.wrappedValue.clearProgress()
          GD.print("✅ Progress cleared. Levels array is now empty: \(progress.wrappedValue.levels.isEmpty)")
        }

      Button$()
        .text("Back")
        .minSize([70, 0])
        .styleBoxes(palette.cyanButtonStylesEnhanced)
        .onSignal(\.pressed) { [state, previousGameState] _ in
          // Go back to previous state (menu or paused)
          state.wrappedValue.gameState = previousGameState
        }
    }
  }

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
            settingsButtons
          }
          .theme(["separation": 2])
        }
        .theme(["marginTop": 4, "marginRight": 4, "marginBottom": 4, "marginLeft": 4])
      }
      .styleBox("panel", palette.settingsPanelStyle)
    }
    .anchorsAndOffsets(.fullRect)
    .visible(state.isSettings)
  }
}

// MARK: - Character/Inventory Overlay

struct Chapter15CharacterOverlay: GView {
  let state: ObservableState<Chapter15GameViewState>
  @State var showOverlay: Bool = false

  let palette = Chapter15Palette()

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
            }
            .styleBox("panel", palette.healthSectionStyle)

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
            }
            .styleBox("panel", palette.inventorySectionStyle)

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
            }
            .styleBox("panel", palette.weaponSectionStyle)

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
            }
            .styleBox("panel", palette.statsSectionStyle)
          }
          .theme(["separation": 4])
        }
        .theme(["separation": 8])
      }
      .styleBox("panel", palette.characterPanelStyle)
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
