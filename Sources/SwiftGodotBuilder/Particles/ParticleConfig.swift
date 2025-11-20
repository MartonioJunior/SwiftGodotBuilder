@preconcurrency import SwiftGodot

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
