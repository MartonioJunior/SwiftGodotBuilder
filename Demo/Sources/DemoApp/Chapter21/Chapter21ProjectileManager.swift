import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct ProjectileManager: GView {
    let pool: ProjectilePool
    let state: ObservableState<GameViewState>

    var body: some GView {
      Node2D$()
        .onReady { node in
          pool.setup(parent: node)
        }
        .onEvent(Event.self) { _, event in
          if case let .projectileFired(position, direction) = event {
            pool.fire(at: position, direction: direction)
          }
        }
        .onProcess { [state] _, delta in
          guard state.wrappedValue.isPlaying else { return }
          pool.update(delta: delta)
        }
    }
  }
}
