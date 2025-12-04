import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct LevelView: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let router: ObservableState<GameRouter>

    private var vm: GameViewState { state.wrappedValue }

    func spawnPlayer(entity: LDEntity) {
      // Set checkpoint position
      vm.lastCheckpointPosition = entity.positionTopLeft

      // Give starting items to player
      let startingItems: [Item] = entity.field("items")?.asEnumArray() ?? []
      for item in startingItems {
        switch item {
        case .coin: vm.coinsCollected += 1
        case .key: vm.hasKey = true
        case .ammo: vm.currentAmmo += 5
        case .health: break // Player starts at full health
        }
      }
    }

    var body: some GView {
      LDLevelView(vm.project, level: state.currentLevelId)
        .onEntity("PlayerSpawn") { entity, _, _ in
          spawnPlayer(entity: entity)
        }
        .onEntitySpawn("EnemySpawn") { entity, _, _ in
          EnemyView(entity: entity, state: state, router: router)
        }
        .onEntitySpawn("BossSpawn") { entity, level, _ in
          BossView(entity: entity, level: level, state: state, settings: settings, router: router)
        }
        .onEntitySpawn("NPCSpawn") { entity, _, _ in
          NPCView(entity: entity)
        }
        .onEntitySpawn("Collectible") { entity, _, _ in
          CollectibleView(entity: entity)
        }
        .onEntitySpawn("Trigger") { entity, _, _ in
          TriggerView(entity: entity, state: state)
        }
        .onEntitySpawn("Platform") { entity, level, _ in
          PlatformView(entity: entity, level: level)
        }
        .onEntitySpawn("Hazard") { entity, _, _ in
          HazardZoneView(entity: entity)
        }
        .onEntitySpawn("Crusher") { entity, level, _ in
          CrusherView(entity: entity, level: level)
        }
    }
  }
}
