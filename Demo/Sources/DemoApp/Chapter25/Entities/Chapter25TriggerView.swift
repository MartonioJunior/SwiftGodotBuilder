import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  enum TriggerType: String, LDExported {
    case checkpoint = "Checkpoint"
    case door = "Door"
    case exit = "Exit"
  }

  /// Unified trigger with composable behavior via LDtk fields
  struct TriggerView: GView {
    // Core properties
    let position: Vector2
    let size: Vector2
    let triggerType: TriggerType

    // Checkpoint-specific
    let id: Int

    // Door-specific
    let requiresItem: Item? // nil = no requirement
    let hasCollision: Bool

    // Computed
    var isCheckpoint: Bool { triggerType == .checkpoint }

    // State
    @State var isActivated = false
    @State var hasTriggered = false

    let state: ObservableState<GameViewState>
    private var vm: GameViewState { state.wrappedValue }

    // Colors
    let checkpointInactive = Color(code: "#808080")
    let checkpointActive = Color(code: "#4DFF4D")
    let doorLocked = Color(code: "#994D1A")
    let doorUnlocked = Color(code: "#33CC3380")
    let exitColor = Color(code: "#4D80E680")

    init(entity: LDEntity, state: ObservableState<GameViewState>) {
      position = entity.positionTopLeft
      size = entity.size
      self.state = state

      // Trigger type
      triggerType = entity.field("triggerType")?.asEnum() ?? .checkpoint

      // Checkpoint
      id = entity.field("id")?.asInt() ?? 0

      // Door
      requiresItem = entity.field("requiresItem")?.asEnum()
      hasCollision = entity.field("hasCollision")?.asBool() ?? false

      // Start unlocked if no item required
      isActivated = requiresItem == nil
    }

    var computedColor: GState<Color> {
      $isActivated.computed { activated in
        if self.isCheckpoint {
          return activated ? self.checkpointActive : self.checkpointInactive
        } else {
          return activated ? self.doorUnlocked : self.doorLocked
        }
      }
    }

    var body: some GView {
      StaticBody2D$ {
        ColorBox$()
          .size(size)
          .color(computedColor)

        // Physical collision (only for blocking triggers, disabled when activated)
        if hasCollision {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: size))
            .position(size / 2)
            .disabled($isActivated)
        }

        // Detection area for interaction
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: hasCollision ? size + [4, 4] : size))
            .position(size / 2)
        }
        .collisionLayer(hasCollision ? 0 : Physics2DLayer.projectile.rawValue)
        .collisionMask(.interaction)
        .onSignal(\.areaEntered) { _, _ in
          handlePlayerContact()
        }
      }
      .position(position)
      .collisionLayer(hasCollision ? Physics2DLayer.terrain.rawValue : 0)
      .watch(state, \.activatedCheckpointIds) { _, activatedIds in
        if isCheckpoint {
          isActivated = activatedIds.contains(id)
        }
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          reset()
        }
      }
    }

    func handlePlayerContact() {
      switch triggerType {
      case .checkpoint:
        guard !isActivated else { return }
        // Defer state change to avoid modifying physics during physics callback
        Engine.onNextFrame {
          isActivated = true
        }
        let respawnPosition: Vector2 = [position.x + size.x / 2, position.y - 4]
        GameEvent.checkpointActivated(id: id, position: respawnPosition).emit()

      case .door:
        // Door just unlocks, doesn't trigger level completion
        if !isActivated {
          if let item = requiresItem, playerHasItem(item) {
            // Defer state change to avoid modifying physics during physics callback
            Engine.onNextFrame {
              isActivated = true
            }
            GameEvent.doorUnlocked(position: position).emit()
          }
        }

      case .exit:
        guard !hasTriggered else { return }
        if let item = requiresItem {
          guard playerHasItem(item) else { return }
        }
        hasTriggered = true
        GameEvent.goalReached.emit()
      }
    }

    func playerHasItem(_ item: Item) -> Bool {
      switch item {
      case .key: return vm.hasKey
      case .coin: return vm.coinsCollected > 0
      case .ammo: return vm.currentAmmo > 0
      case .health: return vm.playerHealth > 0
      }
    }

    func reset() {
      isActivated = requiresItem == nil
      hasTriggered = false
    }
  }
}
