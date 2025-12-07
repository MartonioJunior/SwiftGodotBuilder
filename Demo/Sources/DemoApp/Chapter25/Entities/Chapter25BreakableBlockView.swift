import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct BreakableBlockView: GView {
    let position: Vector2
    let size: Vector2
    let maxHealth: Int
    let dropItem: Item?

    init(entity: LDEntity) {
      position = entity.positionTopLeft
      size = entity.size
      maxHealth = entity.field("health")?.asInt() ?? 2
      dropItem = entity.field("drop")?.asEnum()
    }

    @State var health: Int = 0
    @State var isDestroyed = false

    // Colors for damage states
    let colorFull = Color(code: "#8B7355") // Brown
    let colorDamaged = Color(code: "#6B5344") // Darker brown with cracks
    let colorCritical = Color(code: "#4B3324") // Very dark, about to break

    var currentColor: GState<Color> {
      $health.computed(with: $isDestroyed) { health, destroyed in
        if destroyed { return .transparent }
        let percent = Float(health) / Float(maxHealth)
        if percent > 0.66 { return colorFull }
        if percent > 0.33 { return colorDamaged }
        return colorCritical
      }
    }

    var body: some GView {
      StaticBody2D$ {
        // Visual block
        ColorBox$()
          .size(size)
          .color(currentColor)

        // Add crack overlays at lower health
        ColorBox$()
          .size([2, size.y * 0.6])
          .position([size.x * 0.3, size.y * 0.2])
          .color(Color(code: "#00000033"))
          .bind(\.visible, to: $health) { health in
            Float(health) / Float(maxHealth) <= 0.66
          }

        ColorBox$()
          .size([2, size.y * 0.5])
          .position([size.x * 0.7, size.y * 0.3])
          .color(Color(code: "#00000033"))
          .bind(\.visible, to: $health) { health in
            Float(health) / Float(maxHealth) <= 0.33
          }

        // Collision for terrain
        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
          .watch($isDestroyed) { cs, destroyed in
            Engine.onNextFrame { cs.disabled = destroyed }
          }

        // Hitbox for combat (melee detection)
        // Only MASK for combat - don't BE on combat layer (to avoid detecting other breakables/enemies)
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: size))
            .position(size / 2)
        }
        .collisionLayer(0)
        .collisionMask(.combat)
        .onSignal(\.areaEntered) { _, _ in
          if !isDestroyed {
            takeDamage(1)
          }
        }
      }
      .position(position)
      .collisionLayer(.terrain)
      .bind(\.visible, to: $isDestroyed) { !$0 }
      .onReady { _ in
        health = maxHealth
      }
      .onEvent(GameEvent.self) { _, event in
        switch event {
        case .gameReset:
          health = maxHealth
          isDestroyed = false
        case let .projectileHitEnemy(hitPos):
          // Check if projectile hit us
          let center = position + size / 2
          let distance = Float(hitPos.distanceTo(center))
          if distance < max(size.x, size.y), !isDestroyed {
            takeDamage(1)
          }
        default:
          break
        }
      }
    }

    func takeDamage(_ damage: Int) {
      health -= damage

      let damagePos = position + [size.x / 2, 0]
      GameEvent.damageDealt(amount: damage, position: damagePos).emit()

      if health <= 0 {
        destroy()
      }
    }

    func destroy() {
      isDestroyed = true

      let center = position + size / 2
      GameEvent.enemyKilled(position: center).emit() // Reuse for particles

      // Drop item if configured
      if let item = dropItem {
        switch item {
        case .health:
          GameEvent.healthDropSpawned(position: center).emit()
        case .coin:
          GameEvent.coinCollected(position: center).emit()
        case .ammo:
          GameEvent.ammoCollected(position: center).emit()
        case .key:
          GameEvent.keyCollected(position: center).emit()
        }
      }
    }
  }
}
