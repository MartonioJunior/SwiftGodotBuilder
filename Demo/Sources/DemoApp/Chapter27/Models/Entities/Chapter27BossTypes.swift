import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  enum BossPhase: Int {
    case one = 1
    case two = 2
    case three = 3
    case defeated = 0
  }

  enum BossAttackType {
    case shoot
    case jump
    case charge
    case summon
  }
}
