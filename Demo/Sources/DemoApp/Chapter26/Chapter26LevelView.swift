import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct LevelView: GView {
    let state: ObservableState<GameViewState>
    let player: ObservableState<PlayerState>
    let router: ObservableState<GameRouter>

    var vm: GameViewState { state.wrappedValue }

    /// Derived state for whether gameplay is active (for enemies, etc.)
    var isActive: State<Bool> { router.computed(\.scene.isActive) }

    /// Camera offset for screen shake
    var cameraOffset: State<Vector2> { state.computed(\.cameraOffset) }

    var body: some GView {
      LDLevelView(vm.project, level: state.currentLevelId)
        // Tile layer handlers
        .onTileLayerSpawn("Breakable") { layer, _, project in
          BreakableTerrainView(layer: layer, project: project)
        }
        .onTileLayerSpawn("Hazards") { layer, _, project in
          IntGridZonesView(layer: layer, project: project)
        }
        .onTileLayerSpawn("Environment") { layer, _, project in
          IntGridZonesView(layer: layer, project: project)
        }
        // Entity handlers
        .onEntitySpawn("PlayerSpawn") { entity, level, _ in
          PlayerView(entity: entity, level: level, player: player, isActive: isActive, cameraOffset: cameraOffset)
        }
        .onEntitySpawn("EnemySpawn") { entity, _, _ in
          EnemyView(entity: entity, isActive: isActive)
        }
        .onEntitySpawn("EnemySpawner") { entity, _, _ in
          EnemySpawner(entity: entity, isActive: isActive)
        }
        .onEntitySpawn("BossSpawn") { entity, level, _ in
          BossView(entity: entity, level: level, state: state, router: router)
        }
        .onEntitySpawn("NPCSpawn") { entity, _, _ in
          NPCView(entity: entity)
        }
        .onEntitySpawn("Collectible") { entity, _, _ in
          CollectibleView(entity: entity)
        }
        .onEntitySpawn("Trigger") { entity, _, _ in
          TriggerView(entity: entity, player: player)
        }
        .onEntitySpawn("Doorway") { entity, _, project in
          DoorwayView(entity: entity, state: state, player: player, project: project)
        }
        .onEntitySpawn("Platform") { entity, level, project in
          PlatformView(entity: entity, level: level, project: project)
        }
        .onEntitySpawn("Crusher") { entity, level, project in
          CrusherView(entity: entity, level: level, project: project)
        }
    }
  }
}
