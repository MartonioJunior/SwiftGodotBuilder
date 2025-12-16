import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter27Game: Node2D {
  override func _ready() {
    ReactiveDebug.isEnabled = true
    NodeDebug.isEnabled = true
    ProcessDebug.isEnabled = true

    let project: LDProject

    do {
      project = try LDProject.load(path: "res://Chapter27.ldtk")
    } catch {
      GD.printErr("Failed to load LDtk project: \(error)")
      return
    }

    let rootNode = Chapter27.GameView(project: project).toNode()
    addChild(node: rootNode)
  }
}

enum Chapter27 {
  struct GameView: GView {
    @ObservableState var router = GameRouter(initial: .playing)
    @ObservableState var state: ProjectState
    @ObservableState var player = PlayerGameState()
    @ObservableState var boss = BossState()
    @ObservableState var dialog = DialogGameState()
    @ObservableState var settings = UserSettings()
    @ObservableState var progress = GameProgress()

    init(project: LDProject) {
      _state = ObservableState(wrappedValue: ProjectState(project: project))
    }

    var body: some GView {
      Node2D$ {
        LevelView(state: $state, player: $player, boss: $boss, dialog: $dialog, router: $router, progress: $progress)

        // Spawners
        ParticleSpawner()
        ActorProjectileSpawner(collisionLayers: actorCollisionLayers)
        DropSpawner()
        DamagePopupSpawner()

        SwiftGodotBuilder.AudioManager(settings: $settings) {
          SFXPlayer()
        }

        GameUI(router: $router, state: $state, player: $player, boss: $boss, dialog: $dialog, settings: $settings, progress: $progress)
      }
      .onEvent(GameEvent.self) { _, event in
        switch event {
        case .goalReached:
          if state.handleGoalReached() {
            player.addScore(100)
            router.scene = .levelComplete
          }
        case .playerDied:
          handlePlayerDeath()
        case let .checkpointActivated(id, position):
          state.handleCheckpointActivated(id: id, position: position)
        case .gameReset:
          boss.reset()
          Engine.getSceneTree()?.paused = true
          Engine.onNextFrame {
            Engine.getSceneTree()?.paused = false
          }
        case .bossDefeated:
          player.addScore(500)
        default:
          break
        }
      }
      .onEvent(DialogBusEvent.self) { _, event in
        if case let .emitted(name, _) = event, name == "giveKey" {
          player.hasKey = true
          player.addScore(20)
        }
      }
      .watch($router, \.scene) { _, scene in
        Engine.getSceneTree()?.paused = scene != .playing
      }
      .onReady { _ in
        DisplayServer.windowSetMode(settings.fullscreen ? .fullscreen : .windowed)
        Self.installActions()
        if let firstLevel = state.project.levels.first {
          state.prepareLevel(firstLevel.identifier)
          player.fullReset()
        }
      }
      .onProcess { _, delta in
        guard let scene = Engine.getSceneTree() else { return }
        if router.scene == .playing, !scene.paused {
          state.playTime += delta
        }
      }
    }

    func handlePlayerDeath() {
      let targetScene = player.handlePlayerDied()
      if targetScene == .death {
        router.scene = .death
      } else {
        router.navigate(to: .gameOver, transition: .fade(duration: 0.8))
      }
    }
  }
}
