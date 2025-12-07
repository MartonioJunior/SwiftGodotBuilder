import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct LevelView: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let router: ObservableState<GameRouter>

    private var vm: GameViewState { state.wrappedValue }

    var body: some GView {
      LDLevelView(vm.project, level: state.currentLevelId)
        // Tile layer handlers
        .onTileLayerSpawn("Breakable") { layer, _, project in
          BreakableTerrainView(layer: layer, project: project)
        }
        // Entity handlers
        .onEntitySpawn("PlayerSpawn") { entity, level, _ in
          PlayerView(entity: entity, level: level, state: state, settings: settings, router: router)
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
        .onEntitySpawn("Doorway") { entity, _, _ in
          DoorwayView(entity: entity, state: state)
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
        .onEntitySpawn("BreakableBlock") { entity, _, _ in
          BreakableBlockView(entity: entity)
        }
    }
  }
}
