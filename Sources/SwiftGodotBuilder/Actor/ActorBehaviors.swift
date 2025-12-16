import SwiftGodot

// MARK: - Actor Behavior Events

/// Events emitted by actor behaviors
public enum ActorBehaviorEvent: EmittableEvent {
  /// Actor behavior triggered a shoot action
  case shoot(actorId: Int, position: Vector2, direction: Vector2)

  /// Actor behavior triggered a summon action
  case summon(actorId: Int, position: Vector2)
}

// MARK: - Actor Behavior Enum

/// Composable behaviors that can be added to any actor
public enum ActorBehavior: Sendable {
  /// Path-based patrol between two points (uses LDtk patrol bounds)
  case pathPatrol(ActorPathPatrol)

  /// Arena patrol - bounce between level bounds
  case arenaPatrol(ActorArenaPatrol)

  /// Sine wave movement for flying enemies
  case sineWave(ActorSineWave)

  /// Charge attack - fast movement in one direction until hitting wall
  case charge(ActorCharge)

  /// Attack patterns - phase-based attacks with cooldowns
  case attackPatterns(ActorAttackPatterns)

  /// Shooting on interval (simple, non-phase-based)
  case shoot(ActorShoot)
}

// MARK: - Behavior Runtime State

/// Holds runtime state for all behaviors on an actor
public class ActorBehaviorState {
  // Path patrol
  public var patrolDirection: Float = 1

  // Arena patrol
  public var arenaDirection: Float = -1

  // Sine wave
  public var sineTimer: Double = 0

  // Charge
  public var isCharging = false
  public var chargeDirection: Float = 0

  // Attack patterns
  public var attackTimers: [Double] = []

  // Simple shoot
  public var shootTimer: Double = 0

  public init() {}

  public func reset() {
    patrolDirection = 1
    arenaDirection = -1
    sineTimer = 0
    isCharging = false
    chargeDirection = 0
    attackTimers = []
    shootTimer = 0
  }
}

// MARK: - Path Patrol Config

/// Configuration for path-based patrol (between two points)
public struct ActorPathPatrol: Sendable {
  public let leftBound: Float
  public let rightBound: Float
  public let speed: Float

  public init(leftBound: Float, rightBound: Float, speed: Float = 30) {
    self.leftBound = leftBound
    self.rightBound = rightBound
    self.speed = speed
  }

  public static func fromBounds(_ left: Float, _ right: Float, speed: Float = 30) -> ActorPathPatrol {
    ActorPathPatrol(leftBound: left, rightBound: right, speed: speed)
  }
}

// MARK: - Arena Patrol Config

/// Configuration for arena-based patrol (bounce between walls)
public struct ActorArenaPatrol: Sendable {
  public let leftBound: Float
  public let rightBound: Float
  public let baseSpeed: Float
  public let phaseSpeedMultiplier: [Int: Float]

  public init(
    leftBound: Float,
    rightBound: Float,
    baseSpeed: Float = 30,
    phaseSpeedMultiplier: [Int: Float] = [:]
  ) {
    self.leftBound = leftBound
    self.rightBound = rightBound
    self.baseSpeed = baseSpeed
    self.phaseSpeedMultiplier = phaseSpeedMultiplier
  }

  public func speed(forPhase phase: Int) -> Float {
    baseSpeed * (phaseSpeedMultiplier[phase] ?? 1.0)
  }

  public static func boss(levelWidth: Float) -> ActorArenaPatrol {
    ActorArenaPatrol(
      leftBound: 10,
      rightBound: levelWidth - 10,
      baseSpeed: 30,
      phaseSpeedMultiplier: [1: 1.0, 2: 1.5, 3: 2.0]
    )
  }
}

// MARK: - Sine Wave Config

/// Configuration for sine wave movement (flying enemies)
public struct ActorSineWave: Sendable {
  public let amplitude: Float
  public let frequency: Double
  public let baseY: Float?

  public init(amplitude: Float = 30, frequency: Double = 2.0, baseY: Float? = nil) {
    self.amplitude = amplitude
    self.frequency = frequency
    self.baseY = baseY
  }
}

// MARK: - Charge Attack Config

/// Configuration for charge attack behavior
public struct ActorCharge: Sendable {
  public let speed: Float
  public let stunOnWallHit: Bool
  public let wallStunDuration: Double

  public init(
    speed: Float = 200,
    stunOnWallHit: Bool = true,
    wallStunDuration: Double = 0.5
  ) {
    self.speed = speed
    self.stunOnWallHit = stunOnWallHit
    self.wallStunDuration = wallStunDuration
  }
}

// MARK: - Attack Patterns Config

/// Types of attacks an actor can perform
public enum ActorAttackType: Sendable {
  case shoot
  case jump
  case charge
  case summon
}

/// Configuration for a single attack pattern
public struct ActorAttackPattern: Sendable {
  public let type: ActorAttackType
  public let baseCooldown: Double
  public let minPhase: Int
  public let cooldownMultiplier: [Int: Double]

  public init(
    type: ActorAttackType,
    cooldown: Double,
    minPhase: Int = 1,
    cooldownMultiplier: [Int: Double] = [:]
  ) {
    self.type = type
    baseCooldown = cooldown
    self.minPhase = minPhase
    self.cooldownMultiplier = cooldownMultiplier
  }

  public func cooldown(forPhase phase: Int) -> Double {
    baseCooldown * (cooldownMultiplier[phase] ?? 1.0)
  }
}

/// Container for multiple attack patterns
public struct ActorAttackPatterns: Sendable {
  public let patterns: [ActorAttackPattern]

  public init(_ patterns: [ActorAttackPattern]) {
    self.patterns = patterns
  }
}

// MARK: - Simple Shoot Config

/// Configuration for simple interval-based shooting
public struct ActorShoot: Sendable {
  public let interval: Double
  public let projectileOffset: Vector2

  public init(interval: Double = 2.0, projectileOffset: Vector2 = .zero) {
    self.interval = interval
    self.projectileOffset = projectileOffset
  }
}
