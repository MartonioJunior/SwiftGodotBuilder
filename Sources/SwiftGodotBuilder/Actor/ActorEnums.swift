import Foundation
import SwiftGodot

// MARK: - Facing Direction

/// Facing direction for actors
public enum Facing: Sendable {
  case left
  case right

  public var sign: Float {
    switch self {
    case .left: -1
    case .right: 1
    }
  }
}

// MARK: - Movement Action Status

/// Movement action status
public enum ActorMoveStatus: Sendable {
  case idle
  case walking
  case jumping
  case falling
  case wallSliding
  case dashing
  case swimming
}

// MARK: - Attack Phase

/// Attack phase state machine: idle -> startup -> active -> recovery -> idle
public enum AttackPhase: Sendable {
  case idle
  case startup
  case active
  case recovery

  public var isAttacking: Bool {
    self != .idle
  }

  public var hitboxActive: Bool {
    self == .active
  }
}

