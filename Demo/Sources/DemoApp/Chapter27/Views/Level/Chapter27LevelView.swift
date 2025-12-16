import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct LevelView: GView {
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>
    let boss: ObservableState<BossState>
    let dialog: ObservableState<DialogGameState>
    let router: ObservableState<GameRouter>
    let progress: ObservableState<GameProgress>

    // Pool for direct particle spawning (melee impacts, etc.)
    let directParticlePool = TypedParticlePool<ParticleType, CPUParticles2D>(
      keys: [.meleeImpact],
      config: .init(prewarmPerType: 10, defaultLifetime: 1.0),
      factory: { $0.makeNode() }
    )

    var vm: ProjectState { state.wrappedValue }

    var body: some GView {
      Node2D$ {
        Node2D$()
          .onReady { node in
            directParticlePool.setup(parent: node)
          }

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
            PlayerActorView(entity: entity, level: level, state: state, player: player, boss: boss, dialog: dialog, router: router, progress: progress, particlePool: directParticlePool)
          }
          .onEntitySpawn("EnemySpawn") { entity, _, _ in
            EnemyActorView(entity: entity, worldGravity: vm.gravity)
          }
          .onEntitySpawn("EnemySpawner") { entity, _, _ in
            EnemySpawner(entity: entity, worldGravity: vm.gravity)
          }
          .onEntitySpawn("BossSpawn") { entity, level, _ in
            BossActorView(entity: entity, level: level, boss: boss, router: router, worldGravity: vm.gravity)
          }
          .onEntitySpawn("NPCSpawn") { entity, _, _ in
            NPCActorView(entity: entity, worldGravity: vm.gravity)
          }
          .onEntitySpawn("Collectible") { entity, _, _ in
            ConsumablePickupView(entity: entity)
          }
          .onEntitySpawn("WeaponPickup") { entity, _, _ in
            guard let view = WeaponPickupView(entity: entity) else {
              GD.printErr("[LevelView] WeaponPickup entity missing weaponId field")
              return EmptyGView()
            }
            return view
          }
          .onEntitySpawn("AmmoPickup") { entity, _, _ in
            guard let view = AmmoPickupView(entity: entity) else {
              GD.printErr("[LevelView] AmmoPickup entity missing weaponId field")
              return EmptyGView()
            }
            return view
          }
          .onEntitySpawn("Doorway") { entity, level, project in
            DoorwayView(entity: entity, level: level, project: project)
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
}
