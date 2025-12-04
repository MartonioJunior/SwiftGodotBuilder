import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter24Game: Node2D {
  override func _ready() {
    let project: LDProject

    do {
      project = try LDProject.load(path: "res://Chapter24.ldtk")
    } catch {
      GD.printErr("Failed to load LDtk project: \(error)")
      return
    }

    let rootNode = Chapter24.GameView(project: project).toNode()
    addChild(node: rootNode)
  }
}

extension Chapter24 {
  struct GameView: GView {
    @ObservableState var router = GameRouter(initial: .splash)
    @ObservableState var state: GameViewState
    @ObservableState var settings = GameSettings()
    @ObservableState var progress = GameProgress()

    init(project: LDProject) {
      self._state = ObservableState(wrappedValue: GameViewState(project: project))
    }

    var body: some GView {
      Node2D$ {
        LevelView(state: $state, settings: $settings, router: $router)

        PlayerView(state: $state, settings: $settings, router: $router)

        // Spawners
        ParticleSpawner()
        ProjectileSpawner()
        EnemyProjectileSpawner()
        HealthDropSpawner()

        AudioManager(state: $state, settings: $settings)

        GameUI(router: $router, state: $state, settings: $settings, progress: $progress)
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
        case .coinCollected:
          state.handleCoinCollected()
        case .keyCollected:
          state.handleKeyCollected()
        case .ammoCollected:
          state.handleAmmoCollected()
        case .healthCollected:
          state.handleHealthCollected()
        case let .checkpointActivated(id, position):
          state.handleCheckpointActivated(id: id, position: position)
        case .bossHit:
          applyScreenShake(intensity: 0.3)
        case .bossPhaseChanged:
          applyScreenShake(intensity: 1.0)
          applyScreenFlash()
        case .bossDefeated:
          applyScreenShake(intensity: 1.5)
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
          state.handleKeyCollected()
        }
      }
      .watch($router, \.scene) { _, scene in
        // Pause game tree when not playing
        Engine.getSceneTree()?.paused = scene != .playing
      }
      .onReady { _ in
        DisplayServer.windowSetMode(settings.fullscreen ? .fullscreen : .windowed)
        Self.installActions()
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

extension Chapter24.GameView {
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

  func handlePlayerDeath(at _: Vector2) {
    guard let targetScene = state.handlePlayerDied(currentScene: router.scene) else { return }

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
    makeDialog: (DialogState, Chapter24.GameViewState, Chapter24.GameProgress) -> DialogDefinition?
  ) {
    let visitCount = state.beginDialogVisit(npcId: npcId)
    let dialogState = DialogState(visitCount: visitCount)

    guard let dialog = makeDialog(dialogState, state, progress) else { return }

    if state.prepareDialog(npcId: npcId, dialog: dialog, branchId: nil, currentScene: router.scene) {
      router.scene = .dialog
    }
  }
}
