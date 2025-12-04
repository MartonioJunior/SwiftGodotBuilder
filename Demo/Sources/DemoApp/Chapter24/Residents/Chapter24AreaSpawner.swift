import SwiftGodotBuilder

extension Chapter24 {
  struct AreaSpawner: GView {
    let pool: AreaPool

    var body: some GView {
      Node2D$()
        .onReady { _ in pool.start() }
        .onProcess { _, delta in pool.update(delta: delta) }
    }
  }
}
