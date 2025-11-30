import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter23Game: Node2D {
  override func _ready() {
    let rootNode = Chapter23.GameView().toNode()
    addChild(node: rootNode)
  }
}

extension Chapter23 {
  struct GameView: GView {
    let viewportWidth: Float = 428
    let viewportHeight: Float = 240
    let platformHeight: Float = 8
    let gravity: Float = 400

    @ObservableState var router = GameRouter(initial: .splash)
    @ObservableState var state = GameViewState()
    @ObservableState var settings = GameSettings()
    @ObservableState var progress = GameProgress()

    // Object pools for performance
    let particlePool = ParticlePool()
    let projectilePool = ProjectilePool(maxSize: 30, isEnemy: false)
    let enemyProjectilePool = ProjectilePool(maxSize: 30, isEnemy: true)

    var currentLevelData: LevelData? {
      Chapter23.getLevelData(state.currentLevelId)
    }

    var playerSpawnPoint: Vector2 {
      currentLevelData?.playerSpawnPoint ?? [40, 100]
    }

    var levelWidth: Float {
      currentLevelData?.levelWidth ?? 800
    }

    var body: some GView {
      Node2D$ {
        // Game content - only visible when actually in a level
        Node2D$ {
          Switch($state.currentLevelId) {
            Case(1) { Level1(state: $state, router: $router) }
            Case(2) { Level2(state: $state, router: $router) }
            Case(3) { Level3(state: $state, router: $router) }
            Case(4) { Level4(state: $state, router: $router) }
          }
          .mode(.destroy)

          Player(
            spawnPoint: playerSpawnPoint,
            screenWidth: levelWidth,
            screenHeight: viewportHeight,
            gravity: gravity,
            state: $state,
            router: $router
          )
        }
        .watch($router, \.scene) { node, scene in
          // Show game content only when in-game
          node.visible = scene.isInGame
        }

        GameUI(router: $router, state: $state, settings: $settings, progress: $progress)
        ParticleSpawner(pool: particlePool)
        ProjectileManager(pool: projectilePool, router: $router)
        EnemyProjectileManager(pool: enemyProjectilePool, router: $router)
        HealthDropManager()
        AudioManager(state: $state, settings: $settings)
      }
      .onEvent(Event.self) { [router] _, event in
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

        Actions {
          ActionRecipes.axisLR(
            namePrefix: "move",
            device: 0,
            axis: .leftX,
            dz: 0.2,
            keyLeft: .a,
            keyRight: .d
          )

          ActionRecipes.axisUD(
            namePrefix: "move",
            device: 0,
            axis: .leftY,
            dz: 0.2,
            keyDown: .s,
            keyUp: .w
          )

          Action("move_left") {
            Key(.left)
            JoyButton(.dpadLeft, device: 0)
          }

          Action("move_right") {
            Key(.right)
            JoyButton(.dpadRight, device: 0)
          }

          Action("move_up") {
            Key(.up)
            JoyButton(.dpadUp, device: 0)
          }

          Action("move_down") {
            Key(.down)
            JoyButton(.dpadDown, device: 0)
          }

          Action("jump") {
            Key(.space)
            Key(.w)
            Key(.up)
            JoyButton(.a, device: 0)
            JoyButton(.dpadUp, device: 0)
          }

          Action("attack") {
            Key(.x)
            JoyButton(.x, device: 0)
          }

          Action("dash") {
            Key(.shift)
            JoyButton(.rightShoulder, device: 0)
            JoyButton(.leftShoulder, device: 0)
          }

          Action("switch_weapon") {
            Key(.q)
            JoyButton(.y, device: 0)
          }

          Action("start") {
            Key(.space)
            JoyButton(.a, device: 0)
            JoyButton(.start, device: 0)
          }

          Action("pause") {
            Key(.escape)
            JoyButton(.start, device: 0)
          }

          Action("character_sheet") {
            Key(.tab)
            JoyButton(.back, device: 0)
          }

          // UI navigation actions
          Action("ui_up") {
            Key(.up)
            Key(.w)
            JoyButton(.dpadUp, device: 0)
          }

          Action("ui_down") {
            Key(.down)
            Key(.s)
            JoyButton(.dpadDown, device: 0)
          }

          Action("ui_left") {
            Key(.left)
            Key(.a)
            JoyButton(.dpadLeft, device: 0)
          }

          Action("ui_right") {
            Key(.right)
            Key(.d)
            JoyButton(.dpadRight, device: 0)
          }

          Action("ui_accept") {
            Key(.enter)
            Key(.space)
            JoyButton(.a, device: 0)
          }

          Action("ui_cancel") {
            Key(.escape)
            JoyButton(.b, device: 0)
          }

          Action("interact") {
            Key(.e)
            Key(.enter)
            JoyButton(.a, device: 0)
          }
        }.install()
      }
      .onProcess { [router] _, delta in
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

extension Chapter23.GameView {
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

  func handlePlayerDeath(at position: Vector2) {
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
    makeDialog: (DialogState, Chapter23.GameViewState, Chapter23.GameProgress) -> DialogDefinition?
  ) {
    let visitCount = state.beginDialogVisit(npcId: npcId)
    let dialogState = DialogState(visitCount: visitCount)

    guard let dialog = makeDialog(dialogState, state, progress) else { return }

    if state.prepareDialog(npcId: npcId, dialog: dialog, branchId: nil, currentScene: router.scene) {
      router.scene = .dialog
    }
  }
}
