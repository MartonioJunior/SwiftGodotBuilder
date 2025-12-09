import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct CollectibleSpawner: GView {
    var body: some GView {
      NodeSpawner(GameEvent.self) { event in
        if case let .collectibleSpawned(item, position) = event {
          return CollectibleView(position: position, item).toNode()
        }
        return nil
      } resetWhen: { event in
        if case .gameReset = event { return true }
        return false
      }
    }
  }
}
