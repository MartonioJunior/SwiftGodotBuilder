import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter26Game: Node2D {
  override func _ready() {
    let project: LDProject

    do {
      project = try LDProject.load(path: "res://Chapter26.ldtk")
    } catch {
      GD.printErr("Failed to load LDtk project: \(error)")
      return
    }

    let rootNode = Chapter26.GameView(project: project).toNode()
    addChild(node: rootNode)
  }
}

extension Chapter26 {
  struct GameView: GView {
    @ObservableState var router = GameRouter(initial: .playing)
    @ObservableState var state: GameViewState
    @ObservableState var player = PlayerState()
    @ObservableState var settings = GameSettings()
    @ObservableState var progress = GameProgress()

    init(project: LDProject) {
      _state = ObservableState(wrappedValue: GameViewState(project: project))
    }

    var body: some GView {
      Node2D$ {
        LevelView(state: $state, player: $player, router: $router)

        // Spawners
        ParticleSpawner()
        ProjectileSpawner()
        EnemyProjectileSpawner()
        CollectibleSpawner()
        DamagePopupSpawner()

        SwiftGodotBuilder.AudioManager(settings: $settings) {
          SFXPlayer()
        }

        GameUI(router: $router, state: $state, player: $player, settings: $settings, progress: $progress)
      }
      .onEvent(GameEvent.self) { _, event in
        switch event {
        case .goalReached:
          if state.handleGoalReached(progress: progress, currentScene: router.scene) {
            router.scene = .levelComplete
          }
        case let .playerDied(position):
          handlePlayerDeath(at: position)
        case .enemyKilled:
          state.handleEnemyKilled()
        case .playerHit:
          applyScreenShake(intensity: 0.5)
          applyScreenFlash()
        case let .collected(item, _):
          state.handleCollected(item, player: player)
        case let .checkpointActivated(id, position):
          state.handleCheckpointActivated(player: player, id: id, position: position)
        case let .enterDoor(targetEntityIid):
          handleEnterDoor(targetEntityIid: targetEntityIid)
        case let .enterCrossLevelDoor(targetLevelIid, targetEntityIid):
          handleCrossLevelDoor(targetLevelIid: targetLevelIid, targetEntityIid: targetEntityIid)
        case .bossHit:
          applyScreenShake(intensity: 0.3)
        case .bossPhaseChanged:
          applyScreenShake(intensity: 1.0)
          applyScreenFlash()
        case .bossDefeated:
          applyScreenShake(intensity: 1.5)
        case .meleeHitEnemy:
          applyHitstop(frames: 3)
        case .gameReset:
          Engine.getSceneTree()?.paused = true
          Engine.onNextFrame {
            Engine.getSceneTree()?.paused = false
          }
        default:
          break
        }
      }
      .onEvent(DialogEvent.self) { _, event in
        switch event {
        case let .started(npcId, makeDialog):
          handleDialogStarted(npcId: npcId, makeDialog: makeDialog)
        default:
          break
        }
      }
      .onEvent(DialogBusEvent.self) { _, event in
        if case let .emitted(name, _) = event, name == "giveKey" {
          state.handleCollected(.key, player: player)
        }
      }
      .watch($router, \.scene) { _, scene in
        // Pause game tree when not playing
        Engine.getSceneTree()?.paused = scene != .playing
      }
      .onReady { _ in
        DisplayServer.windowSetMode(settings.fullscreen ? .fullscreen : .windowed)
        Self.installActions()
        // Load first level
        if let firstLevel = state.project.levels.first {
          state.prepareLevel(firstLevel.identifier, player: player)
        }
      }
      .onProcess { _, delta in
        if router.scene == .playing {
          state.playTime += delta
        }

        if state.cameraOffset.length() > 0.01 {
          state.cameraOffset = state.cameraOffset.lerp(to: .zero, weight: 10.0 * delta)
        } else if state.cameraOffset != .zero {
          state.cameraOffset = .zero
        }

        if state.screenFlashAlpha > 0 {
          state.screenFlashAlpha = max(0, state.screenFlashAlpha - Float(delta) * 3.0)
        }
      }
    }
  }
}

extension Chapter26.GameView {
  func applyScreenShake(intensity: Float) {
    let angle = Float.random(in: 0 ..< Float.pi * 2)
    let distance = intensity * 10.0
    state.cameraOffset = [cos(angle) * distance, sin(angle) * distance]

    Engine.timeScale = 0.0
    Engine.onNextFrame {
      Engine.timeScale = 1.0
    }
  }

  func applyScreenFlash() {
    state.screenFlashAlpha = 0.5
  }

  /// Brief pause on hit for impact feel (hitstop/hitlag)
  func applyHitstop(frames _: Int) {
    Engine.timeScale = 0.0
    // Use onNextFrame to resume after one frame pause (simpler than timer)
    Engine.onNextFrame {
      Engine.timeScale = 1.0
    }
  }

  func handlePlayerDeath(at _: Vector2) {
    guard let targetScene = state.handlePlayerDied(player: player, currentScene: router.scene) else { return }

    if targetScene == .death {
      // Show death screen (no transition - it handles its own animation)
      router.scene = .death
    } else {
      // Game over - fade transition
      router.navigate(to: .gameOver, transition: .fade(duration: 0.8))
    }
  }

  func handleDialogStarted(
    npcId: String,
    makeDialog: (DialogState, Chapter26.GameViewState, Chapter26.PlayerState, Chapter26.GameProgress) -> DialogDefinition?
  ) {
    let visitCount = state.beginDialogVisit(npcId: npcId)
    let dialogState = DialogState(visitCount: visitCount)

    guard let dialog = makeDialog(dialogState, state, player, progress) else { return }

    if state.prepareDialog(npcId: npcId, dialog: dialog, branchId: nil, currentScene: router.scene) {
      router.scene = .dialog
    }
  }

  /// Handle doorway teleportation (intra-level) with quick fade
  func handleEnterDoor(targetEntityIid: String) {
    guard let targetPosition = state.doorPositions[targetEntityIid] else {
      GD.printErr("Door with IID '\(targetEntityIid)' not found in level")
      return
    }

    // Offset to center player on door with feet at door bottom
    let playerSpawnPosition = targetPosition - [state.playerSize.x / 2, state.playerSize.y]

    // Quick fade transition for door teleportation
    router.navigate(to: .playing, transition: .fade(duration: 0.3)) {
      // Teleport player to target door position
      Chapter26.GameEvent.doorTeleportComplete(position: playerSpawnPosition).emit()
    }
  }

  /// Handle cross-level door transition with iris effect
  func handleCrossLevelDoor(targetLevelIid: String, targetEntityIid: String) {
    // Look up the target level by IID
    guard let targetLevel = state.project.level(iid: targetLevelIid) else {
      GD.printErr("Target level with IID '\(targetLevelIid)' not found")
      return
    }

    guard let targetDoor = targetLevel.entity(iid: targetEntityIid) else { return }
    let targetDoorPosition = targetDoor.positionTopLeft
    let doorSize = targetDoor.size

    router.navigate(to: .playing, transition: .iris(duration: 1.0)) {
      state.prepareLevel(targetLevel.identifier, player: player)

      // Center player on door with feet at door bottom
      let doorCenterX = targetDoorPosition.x + doorSize.x / 2
      let spawnPos: Vector2 = [doorCenterX - state.playerSize.x / 2, targetDoorPosition.y + doorSize.y - state.playerSize.y]
      Chapter26.GameEvent.doorTeleportComplete(position: spawnPos).emit()
    }
  }
}
