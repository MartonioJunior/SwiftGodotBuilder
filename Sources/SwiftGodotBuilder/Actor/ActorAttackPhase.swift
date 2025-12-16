/// Attack phase for melee combat timing systems.
///
/// Models a state machine for attacks with distinct phases:
/// - **idle**: Not attacking
/// - **startup**: Anticipation/windup, no hitbox active
/// - **active**: Hitbox is live, can deal damage
/// - **recovery**: Commitment window after attack, no hitbox
public enum ActorAttackPhase: Sendable {
  /// Not attacking
  case idle

  /// Anticipation/windup - no hitbox
  case startup

  /// Hitbox is live - can deal damage
  case active

  /// Commitment window - no hitbox
  case recovery

  /// Whether currently in any attack phase (not idle)
  public var isAttacking: Bool {
    switch self {
    case .idle: false
    case .startup, .active, .recovery: true
    }
  }

  /// Whether the hitbox should be active and dealing damage
  public var hitboxActive: Bool { self == .active }

  /// Get the next phase in the attack sequence
  public func next() -> ActorAttackPhase {
    switch self {
    case .idle: .idle
    case .startup: .active
    case .active: .recovery
    case .recovery: .idle
    }
  }
}

typealias AttackPhase = ActorAttackPhase
