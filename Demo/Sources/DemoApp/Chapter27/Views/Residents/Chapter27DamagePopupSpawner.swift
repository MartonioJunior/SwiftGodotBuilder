import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct DamagePopupSpawner: GView {
    let damageColor = Color(code: "#FF6644")

    var body: some GView {
      FloatingTextSpawner(GameEvent.self) { event in
        if case let .enemyTookDamage(amount, position) = event {
          return (text: "\(amount)", position: position, color: damageColor)
        }
        return nil
      }
    }
  }
}
