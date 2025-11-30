import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct EnemyProjectileManager: GView {
    let pool: ProjectilePool
    let router: ObservableState<GameRouter>

    var body: some GView {
      Node2D$()
        .onReady { node in
          pool.setup(parent: node)
        }
        .onEvent(Event.self) { _, event in
          if case let .enemyProjectileFired(position, direction) = event {
            pool.fire(at: position, direction: direction)
          }
        }
        .onProcess { [router] _, delta in
          guard router.scene.isActive else { return }
          pool.update(delta: delta)
        }
    }
  }
}
