import Foundation
import SwiftGodot

// MARK: - Idle Behavior

/// Does nothing - useful as a state placeholder
public struct Idle: ActorBehavior {
  public init() {}

  public func process(actor: ActorState, delta _: Double) {
    actor.physics?.inputDirection = 0
  }

  public func enter(actor _: ActorState) {}
  public func exit(actor _: ActorState) {}
}

// MARK: - Patrol Behavior

/// Patrols back and forth relative to spawn position
/// `left` and `right` are offsets from the initial position when entering this behavior
public struct Patrol: ActorBehavior {
  public let leftOffset: Float
  public let rightOffset: Float
  public let speed: Float?

  private var direction: Float = 1
  private var leftBound: Float = 0
  private var rightBound: Float = 0

  /// Create a patrol behavior
  /// - Parameters:
  ///   - left: Distance to patrol left from spawn
  ///   - right: Distance to patrol right from spawn
  ///   - speed: Override speed (defaults to actor's physics speed)
  public init(left: Float, right: Float, speed: Float? = nil) {
    leftOffset = left
    rightOffset = right
    self.speed = speed
  }

  public mutating func process(actor: ActorState, delta _: Double) {
    guard let physics = actor.physics, let node = actor.node else { return }

    let pos = node.position.x

    // Reverse at bounds
    if pos <= leftBound {
      direction = 1
    } else if pos >= rightBound {
      direction = -1
    }

    // Use physics speed by default, or scale input if speed override provided
    if let speed, physics.config.speed > 0 {
      physics.inputDirection = direction * (speed / physics.config.speed)
    } else {
      physics.inputDirection = direction
    }
  }

  public mutating func enter(actor: ActorState) {
    // Calculate absolute bounds from spawn position
    let spawnX = actor.node?.position.x ?? 0
    leftBound = spawnX - leftOffset
    rightBound = spawnX + rightOffset
    direction = actor.facing == .right ? 1 : -1
  }

  public func exit(actor _: ActorState) {}
}

// MARK: - Shoot Behavior

/// Fires projectiles on an interval (uses weapon's RangedWeaponConfig.spawnOffset for positioning)
public struct Shoot: ActorBehavior {
  public let cooldown: Double

  private var timer: Double = 0

  public init(cooldown: Double = 2.0) {
    self.cooldown = cooldown
  }

  public mutating func process(actor: ActorState, delta: Double) {
    timer -= delta

    if timer <= 0 {
      timer = cooldown

      // Request attack if actor has weapon capability
      if let weapon = actor.weapon {
        weapon.attackRequested = true
      }
    }
  }

  public mutating func enter(actor _: ActorState) {
    timer = cooldown * 0.5 // Start with half cooldown for quicker first shot
  }

  public func exit(actor _: ActorState) {}
}

// MARK: - Chase Behavior

/// Chases toward the current target
public struct Chase: ActorBehavior {
  public let speed: Float?
  public let stopDistance: Float

  /// Create a chase behavior
  /// - Parameters:
  ///   - speed: Override speed (defaults to actor's physics speed)
  ///   - stopDistance: Stop when this close to target
  public init(speed: Float? = nil, stopDistance: Float = 16) {
    self.speed = speed
    self.stopDistance = stopDistance
  }

  public mutating func process(actor: ActorState, delta _: Double) {
    guard let physics = actor.physics else { return }

    guard let node = actor.node,
          let targeting = actor.targeting,
          let targetPos = targeting.targetPosition
    else {
      physics.inputDirection = 0
      return
    }

    let distance = abs(targetPos.x - node.position.x)
    if distance < stopDistance {
      physics.inputDirection = 0
      return
    }

    let direction: Float = targetPos.x > node.position.x ? 1 : -1

    // Use physics speed by default, or scale input if speed override provided
    if let speed, physics.config.speed > 0 {
      physics.inputDirection = direction * (speed / physics.config.speed)
    } else {
      physics.inputDirection = direction
    }
  }

  public func enter(actor _: ActorState) {}
  public func exit(actor _: ActorState) {}
}

// MARK: - Face Target Behavior

/// Always faces toward the current target
public struct FaceTarget: ActorBehavior {
  public init() {}

  public func process(actor: ActorState, delta _: Double) {
    guard let node = actor.node,
          let targeting = actor.targeting,
          let targetPos = targeting.targetPosition
    else { return }

    actor.facing = targetPos.x > node.position.x ? .right : .left
  }

  public func enter(actor _: ActorState) {}
  public func exit(actor _: ActorState) {}
}

// MARK: - Sine Wave Behavior

/// Moves in a sine wave pattern around spawn position (for flying enemies)
public struct SineWave: ActorBehavior {
  public let amplitudeX: Float
  public let amplitudeY: Float
  public let speed: Float?
  public let phaseOffset: Float

  private var time: Double = 0
  private var spawnPosition: Vector2 = .zero
  private var frequencyX: Float = 1
  private var frequencyY: Float = 1

  /// Create a sine wave movement pattern
  /// - Parameters:
  ///   - amplitudeX: Horizontal distance from center (0 for vertical-only)
  ///   - amplitudeY: Vertical distance from center (0 for horizontal-only)
  ///   - speed: Max movement speed in pixels/second (defaults to actor's physics speed)
  ///   - phaseOffset: Starting phase offset (0-1, useful for staggering multiple enemies)
  public init(
    amplitudeX: Float = 0,
    amplitudeY: Float = 20,
    speed: Float? = nil,
    phaseOffset: Float = 0
  ) {
    self.amplitudeX = amplitudeX
    self.amplitudeY = amplitudeY
    self.speed = speed
    self.phaseOffset = phaseOffset
  }

  public mutating func process(actor: ActorState, delta: Double) {
    guard let node = actor.node else { return }

    time += delta

    let phase = Float(time) + phaseOffset * Float.pi * 2

    let offsetX = amplitudeX * sin(phase * frequencyX * Float.pi * 2)
    let offsetY = amplitudeY * sin(phase * frequencyY * Float.pi * 2)

    let newX = spawnPosition.x + offsetX
    let velocityX = newX - node.position.x

    node.position = Vector2(
      x: newX,
      y: spawnPosition.y + offsetY
    )

    // Update facing based on horizontal movement direction
    if velocityX > 0.1 {
      actor.facing = .right
    } else if velocityX < -0.1 {
      actor.facing = .left
    }
  }

  public mutating func enter(actor: ActorState) {
    spawnPosition = actor.node?.position ?? .zero
    time = 0

    // Derive frequency from speed and amplitude
    // Max velocity of sine wave = amplitude * angular_frequency = amplitude * 2π * frequency
    // So frequency = speed / (amplitude * 2π)
    let effectiveSpeed = speed ?? actor.physics?.config.speed ?? 30

    if amplitudeX > 0 {
      frequencyX = effectiveSpeed / (amplitudeX * Float.pi * 2)
    }
    if amplitudeY > 0 {
      frequencyY = effectiveSpeed / (amplitudeY * Float.pi * 2)
    }
  }

  public func exit(actor _: ActorState) {}
}
