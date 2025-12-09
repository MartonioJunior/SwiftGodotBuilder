/// Attack phase for melee combat timing systems.
///
/// Models a state machine for attacks with distinct phases:
/// - **idle**: Not attacking
/// - **startup**: Anticipation/windup, no hitbox active
/// - **active**: Hitbox is live, can deal damage
/// - **recovery**: Commitment window after attack, no hitbox
///
/// ### Example:
/// ```swift
/// var attackPhase: AttackPhase = .idle
/// var attackTimer = 0.0
///
/// func startAttack() {
///   attackPhase = .startup
///   attackTimer = weapon.startupTime
/// }
///
/// func updateAttack(delta: Double) {
///   attackTimer -= delta
///   if attackTimer <= 0 {
///     attackPhase = attackPhase.next(weapon: weapon)
///     attackTimer = attackPhase.duration(weapon: weapon)
///   }
/// }
/// ```
public enum AttackPhase: Sendable {
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
  public func next() -> AttackPhase {
    switch self {
    case .idle: .idle
    case .startup: .active
    case .active: .recovery
    case .recovery: .idle
    }
  }

  /// Get the duration for this phase from a weapon config
  public func duration(weapon: WeaponConfig) -> Double {
    switch self {
    case .idle: 0
    case .startup: weapon.startupTime
    case .active: weapon.activeTime
    case .recovery: weapon.recoveryTime
    }
  }
}
