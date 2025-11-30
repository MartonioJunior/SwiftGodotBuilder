import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  /// Specialized particle pool that handles CPUParticles2D
  final class ParticlePool {
    private var pools: [ParticleType: [CPUParticles2D]] = [:]
    private var activeCount: [ParticleType: Int] = [:]
    private let palette = Palette.shared
    private weak var parentNode: Node?

    var totalActive: Int {
      activeCount.values.reduce(0, +)
    }

    var totalAvailable: Int {
      pools.values.reduce(0) { total, pool in
        total + pool.filter { !$0.emitting }.count
      }
    }

    func setup(parent: Node) {
      parentNode = parent

      // Create pools for each particle type
      for particleType in ParticleType.allCases {
        pools[particleType] = []
        activeCount[particleType] = 0
      }

      // Pre-warm with 5 particles each, deferred to avoid setup conflicts
      Engine.onNextFrame { [weak self, weak parent] in
        guard let self, let parent else { return }
        for particleType in ParticleType.allCases {
          for _ in 0 ..< 5 {
            let particle = self.createParticle(type: particleType)
            particle.visible = false
            parent.addChild(node: particle)
            self.pools[particleType]?.append(particle)
          }
        }
      }
    }

    func spawn(type: ParticleType, at position: Vector2) {
      guard let parent = parentNode else { return }

      // Find an available particle or create new
      var particle: CPUParticles2D?

      if let pool = pools[type] {
        particle = pool.first { !$0.emitting && !$0.visible }
      }

      if particle == nil {
        // Create new particle if pool exhausted
        let newParticle = createParticle(type: type)
        parent.addChild(node: newParticle)
        pools[type]?.append(newParticle)
        particle = newParticle
      }

      guard let p = particle else { return }

      p.position = position
      p.visible = true
      p.emitting = true
      activeCount[type, default: 0] += 1

      // Schedule return to pool after emission completes
      if let tree = Engine.getSceneTree(),
         let timer = tree.createTimer(timeSec: p.lifetime + 0.1)
      {
        _ = timer.timeout.connect { [weak self, weak p] in
          guard let p else { return }
          p.visible = false
          self?.activeCount[type, default: 1] -= 1
        }
      }
    }

    private func createParticle(type: ParticleType) -> CPUParticles2D {
      let config = getParticleConfig(type: type, palette: palette)
      let particles = CPUParticles2D()
      particles.oneShot = true
      particles.emitting = false
      particles.amount = config.amount
      particles.lifetime = config.lifetime
      particles.explosiveness = config.explosiveness
      particles.direction = config.direction
      particles.spread = config.spread
      particles.initialVelocityMin = config.initialVelocityMin
      particles.initialVelocityMax = config.initialVelocityMax
      particles.gravity = config.gravity
      particles.color = config.color
      return particles
    }

    private func getParticleConfig(type: ParticleType, palette: Palette) -> ParticleConfig {
      switch type {
      case .jumpDust:
        return ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, -1], spread: 45,
          initialVelocityMin: 20, initialVelocityMax: 50,
          gravity: [0, 100], color: palette.particleGray
        )
      case .landingImpact:
        return ParticleConfig(
          amount: 12, lifetime: 0.4, explosiveness: 1.0,
          direction: [0, -1], spread: 60,
          initialVelocityMin: 30, initialVelocityMax: 80,
          gravity: [0, 150], color: palette.particleDarkGray
        )
      case .movementTrail:
        return ParticleConfig(
          amount: 3, lifetime: 0.2, explosiveness: 0.0,
          direction: [0, 0], spread: 20,
          initialVelocityMin: 5, initialVelocityMax: 10,
          gravity: [0, 0], color: palette.particleBlue
        )
      case .deathExplosion:
        return ParticleConfig(
          amount: 30, lifetime: 0.8, explosiveness: 1.0,
          direction: [0, -1], spread: 180,
          initialVelocityMin: 80, initialVelocityMax: 150,
          gravity: [0, 300], color: palette.particleRed
        )
      case .enemyHit:
        return ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, -1], spread: 90,
          initialVelocityMin: 40, initialVelocityMax: 80,
          gravity: [0, 200], color: palette.particleOrange
        )
      case .coinSparkle:
        return ParticleConfig(
          amount: 15, lifetime: 0.5, explosiveness: 1.0,
          direction: [0, -1], spread: 360,
          initialVelocityMin: 20, initialVelocityMax: 60,
          gravity: [0, -50], color: palette.particleYellow
        )
      case .projectileTrail:
        return ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, 0], spread: 180,
          initialVelocityMin: 10, initialVelocityMax: 30,
          gravity: [0, 0], color: palette.particleYellowAlt
        )
      }
    }
  }

  /// Projectile pool that reuses Area2D nodes
  final class ProjectilePool {
    private weak var parentNode: Node?
    private let isEnemy: Bool
    private let maxSize: Int
    private let palette = Palette.shared

    // Pool storage
    private var nodes: [Area2D] = []
    private var positions: [Vector2] = []
    private var velocities: [Vector2] = []
    private var ages: [Double] = []
    private var active: [Bool] = []

    // Projectile settings
    private let speed: Float = 300
    private let lifetime: Double = 3.0
    private let size: Float = 6

    init(maxSize: Int = 30, isEnemy: Bool = false) {
      self.maxSize = maxSize
      self.isEnemy = isEnemy
    }

    func setup(parent: Node) {
      parentNode = parent

      // Pre-warm the pool
      Engine.onNextFrame { [weak self, weak parent] in
        guard let self, let parent else { return }
        for _ in 0 ..< maxSize {
          let node = createProjectileNode()
          node.visible = false
          parent.addChild(node: node)
          nodes.append(node)
          positions.append(.zero)
          velocities.append(.zero)
          ages.append(0)
          active.append(false)
        }
      }
    }

    func fire(at position: Vector2, direction: Vector2) {
      // Find an available projectile
      guard let index = active.firstIndex(of: false) else {
        return // Pool exhausted
      }

      let normalizedDir = direction.normalized()
      positions[index] = position
      velocities[index] = normalizedDir * speed
      ages[index] = 0
      active[index] = true

      let node = nodes[index]
      node.position = position
      node.visible = true
      node.monitorable = true
      node.monitoring = true

      // Update visual rotation based on direction
      if let polygon = node.getChild(idx: 0) as? Polygon2D {
        polygon.polygon = arrowShape(facingRight: normalizedDir.x >= 0)
      }
    }

    func update(delta: Double) {
      for i in 0 ..< nodes.count where active[i] {
        // Update position
        positions[i] += velocities[i] * Float(delta)
        nodes[i].position = positions[i]

        // Update age
        ages[i] += delta

        // Check for timeout or out of bounds
        let pos = positions[i]
        if ages[i] > lifetime || pos.x < -50 || pos.x > 850 || pos.y < -50 || pos.y > 230 {
          returnToPool(index: i, hitEnemy: false)
        }
      }
    }

    func handleCollision(node: Area2D, hitEnemy: Bool) {
      guard let index = nodes.firstIndex(of: node), active[index] else { return }
      returnToPool(index: index, hitEnemy: hitEnemy)
    }

    private func returnToPool(index: Int, hitEnemy: Bool) {
      guard active[index] else { return }
      active[index] = false

      let node = nodes[index]
      node.visible = false
      Engine.onNextFrame {
        node.monitorable = false
        node.monitoring = false
      }

      // Emit appropriate event
      let pos = positions[index]
      if hitEnemy {
        if isEnemy {
          Event.playerHit(damage: 1, position: pos).emit()
        } else {
          Event.projectileHitEnemy(position: pos).emit()
        }
      } else {
        if !isEnemy {
          Event.projectileHitWall(position: pos).emit()
        }
      }
    }

    private func createProjectileNode() -> Area2D {
      let area = Area2D$ {
        Polygon2D$()
          .polygon(arrowShape(facingRight: true))
          .color(isEnemy ? palette.enemyProjectile : palette.projectile)
        CollisionShape2D$()
          .shape(RectangleShape2D(w: size, h: size))
      }
      .collisionLayer(isEnemy ? .epsilon : .delta)
      .collisionMask(isEnemy ? .beta : [.alpha, .delta])
      .onSignal(\.bodyEntered) { [weak self] node, _ in
        guard let self, let area = node as? Area2D else { return }
        self.handleCollision(node: area, hitEnemy: false)
      }
      .onSignal(\.areaEntered) { [weak self] node, _ in
        guard let self, let area = node as? Area2D else { return }
        self.handleCollision(node: area, hitEnemy: true)
      }
      .toNode()

      return area as! Area2D
    }

    private func arrowShape(facingRight: Bool) -> PackedVector2Array {
      if facingRight {
        return PackedVector2Array([[4, 0], [0, -3], [-2, -2], [-2, 2], [0, 3]])
      } else {
        return PackedVector2Array([[-4, 0], [0, -3], [2, -2], [2, 2], [0, 3]])
      }
    }
  }
}

extension Chapter23.ParticleType: CaseIterable {
  static var allCases: [Chapter23.ParticleType] {
    [.jumpDust, .landingImpact, .movementTrail, .deathExplosion, .enemyHit, .coinSparkle, .projectileTrail]
  }
}
