import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Mutually exclusive movement/action states
  enum ActionState {
    case idle
    case walking
    case jumping
    case falling
    case wallSliding
    case dashing
    case swimming
  }

  /// Mutually exclusive damage states
  enum DamageState {
    case normal
    case hit
    case dead
  }

  /// Player facing direction
  enum Facing {
    case left
    case right

    var isRight: Bool { self == .right }
    var sign: Float { self == .right ? 1 : -1 }

    mutating func flip() {
      self = self == .right ? .left : .right
    }
  }

  /// Overlay states that can combine with any action
  enum ActionOverlay {
    case crouching
    case attacking
    case invincible
  }

  typealias ActionOverlayState = Set<ActionOverlay>
}
