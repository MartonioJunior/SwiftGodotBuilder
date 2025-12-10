import SwiftGodot

// MARK: - GNode Extension

public extension GNode where T == CPUParticles2D {
  /// Configure the particle system with a ParticleConfig.
  ///
  /// ## Usage
  /// ```swift
  /// CPUParticles2D$()
  ///   .config(.explosion)
  ///   .oneShot(true)
  ///   .emitting(true)
  /// ```
  func config(_ config: ParticleConfig) -> Self {
    var s = self
    s.ops.append { particles in
      particles.amount = config.amount
      particles.lifetime = config.lifetime
      particles.explosiveness = config.explosiveness
      particles.direction = config.direction
      particles.spread = config.spread
      particles.initialVelocityMin = config.initialVelocityMin
      particles.initialVelocityMax = config.initialVelocityMax
      particles.gravity = config.gravity
      particles.color = config.color
    }
    return s
  }
}

// MARK: - CPUParticles2D Extension

public extension CPUParticles2D {
  /// Apply a ParticleConfig to this particle system.
  func apply(_ config: ParticleConfig) {
    amount = config.amount
    lifetime = config.lifetime
    explosiveness = config.explosiveness
    direction = config.direction
    spread = config.spread
    initialVelocityMin = config.initialVelocityMin
    initialVelocityMax = config.initialVelocityMax
    gravity = config.gravity
    color = config.color
  }

  /// Create a CPUParticles2D configured with the given ParticleConfig.
  convenience init(_ config: ParticleConfig) {
    self.init()
    apply(config)
  }
}

// MARK: - ParticleConfig

/// Configuration for CPUParticles2D emission parameters.
///
/// This struct provides a convenient way to configure particle systems with common parameters.
///
/// ## Usage
///
/// ```swift
/// let explosionConfig = ParticleConfig(
///   amount: 20,
///   lifetime: 0.8,
///   explosiveness: 1.0,
///   direction: Vector2(x: 0, y: -1),
///   spread: 45,
///   initialVelocityMin: 100,
///   initialVelocityMax: 200,
///   gravity: Vector2(x: 0, y: 400),
///   color: Color(r: 1.0, g: 0.5, b: 0.0)
/// )
/// ```
public struct ParticleConfig: Sendable {
  /// Number of particles to emit
  public let amount: Int32

  /// How long each particle lives (in seconds)
  public let lifetime: Double

  /// How quickly particles are emitted (0.0 = steady, 1.0 = all at once)
  public let explosiveness: Double

  /// Base direction for particle emission (normalized)
  public let direction: Vector2

  /// Angle spread in degrees
  public let spread: Double

  /// Minimum initial velocity
  public let initialVelocityMin: Double

  /// Maximum initial velocity
  public let initialVelocityMax: Double

  /// Gravity applied to particles
  public let gravity: Vector2

  /// Particle color
  public let color: Color

  /// Creates a particle configuration.
  ///
  /// - Parameters:
  ///   - amount: Number of particles to emit
  ///   - lifetime: How long each particle lives (in seconds)
  ///   - explosiveness: How quickly particles are emitted (0.0 = steady, 1.0 = all at once)
  ///   - direction: Base direction for particle emission (normalized)
  ///   - spread: Angle spread in degrees
  ///   - initialVelocityMin: Minimum initial velocity
  ///   - initialVelocityMax: Maximum initial velocity
  ///   - gravity: Gravity applied to particles
  ///   - color: Particle color
  public init(
    amount: Int32,
    lifetime: Double,
    explosiveness: Double,
    direction: Vector2,
    spread: Double,
    initialVelocityMin: Double,
    initialVelocityMax: Double,
    gravity: Vector2,
    color: Color
  ) {
    self.amount = amount
    self.lifetime = lifetime
    self.explosiveness = explosiveness
    self.direction = direction
    self.spread = spread
    self.initialVelocityMin = initialVelocityMin
    self.initialVelocityMax = initialVelocityMax
    self.gravity = gravity
    self.color = color
  }
}

// MARK: - Presets

public extension ParticleConfig {
  /// Explosion burst - all particles emitted at once, spreading outward
  static let explosion = ParticleConfig(
    amount: 20,
    lifetime: 0.6,
    explosiveness: 1.0,
    direction: [0, -1],
    spread: 180,
    initialVelocityMin: 80,
    initialVelocityMax: 150,
    gravity: [0, 200],
    color: .white
  )

  /// Sparkle effect - gentle upward drift
  static let sparkle = ParticleConfig(
    amount: 8,
    lifetime: 0.8,
    explosiveness: 0.0,
    direction: [0, -1],
    spread: 30,
    initialVelocityMin: 20,
    initialVelocityMax: 50,
    gravity: [0, -20],
    color: .yellow
  )

  /// Dust puff - quick ground impact effect
  static let dust = ParticleConfig(
    amount: 6,
    lifetime: 0.4,
    explosiveness: 0.8,
    direction: [0, -1],
    spread: 60,
    initialVelocityMin: 30,
    initialVelocityMax: 60,
    gravity: [0, 100],
    color: Color(r: 0.6, g: 0.5, b: 0.4, a: 0.8)
  )

  /// Blood/hit splatter
  static let splatter = ParticleConfig(
    amount: 12,
    lifetime: 0.5,
    explosiveness: 1.0,
    direction: [0, -1],
    spread: 90,
    initialVelocityMin: 60,
    initialVelocityMax: 120,
    gravity: [0, 300],
    color: Color(r: 0.8, g: 0.1, b: 0.1, a: 1.0)
  )

  /// Smoke - slow rising particles
  static let smoke = ParticleConfig(
    amount: 10,
    lifetime: 1.5,
    explosiveness: 0.0,
    direction: [0, -1],
    spread: 20,
    initialVelocityMin: 10,
    initialVelocityMax: 30,
    gravity: [0, -50],
    color: Color(r: 0.3, g: 0.3, b: 0.3, a: 0.5)
  )

  /// Create a custom config with a specific color, based on an existing preset
  func withColor(_ color: Color) -> ParticleConfig {
    ParticleConfig(
      amount: amount,
      lifetime: lifetime,
      explosiveness: explosiveness,
      direction: direction,
      spread: spread,
      initialVelocityMin: initialVelocityMin,
      initialVelocityMax: initialVelocityMax,
      gravity: gravity,
      color: color
    )
  }

  /// Create a custom config with scaled amount
  func withAmount(_ amount: Int32) -> ParticleConfig {
    ParticleConfig(
      amount: amount,
      lifetime: lifetime,
      explosiveness: explosiveness,
      direction: direction,
      spread: spread,
      initialVelocityMin: initialVelocityMin,
      initialVelocityMax: initialVelocityMax,
      gravity: gravity,
      color: color
    )
  }
}
