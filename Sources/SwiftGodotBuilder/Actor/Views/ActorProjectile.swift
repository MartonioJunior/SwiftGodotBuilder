import Foundation
import SwiftGodot

// MARK: - Projectile View

/// A single projectile fired by an actor
public struct ActorProjectileView: GView {
  public let config: RangedWeaponConfig
  public let startPosition: Vector2
  public let direction: Vector2
  public let sourceActorId: Int
  public let isPlayerOwned: Bool

  private final class ViewModel {
    var lifetime: Double = 0
  }

  private let vm = ViewModel()

  public init(
    config: RangedWeaponConfig,
    startPosition: Vector2,
    direction: Vector2,
    sourceActorId: Int,
    isPlayerOwned: Bool
  ) {
    self.config = config
    self.startPosition = startPosition
    self.direction = direction
    self.sourceActorId = sourceActorId
    self.isPlayerOwned = isPlayerOwned
  }

  private var defaultColor: Color {
    isPlayerOwned ? Color(code: "#AAAAFF") : Color(code: "#FF4444")
  }

  // Collision layers matching Actor.swift:
  // Player projectile: layer=.delta (playerAttack), mask=.iota (enemyHurtbox) + .alpha (terrain)
  // Enemy projectile: layer=.kappa (enemyAttack), mask=.theta (playerHurtbox) + .alpha (terrain)
  private var projectileLayer: Physics2DLayer {
    isPlayerOwned ? .delta : .kappa
  }

  private var targetMask: Physics2DLayer {
    // Player projectiles hit enemy hurtboxes (.iota)
    // Enemy projectiles hit player hurtboxes (.theta) AND other enemy hurtboxes (.iota)
    let hurtboxLayers: Physics2DLayer = isPlayerOwned ? .iota : [.theta, .iota]
    return Physics2DLayer([hurtboxLayers, .alpha])
  }

  public var body: some GView {
    Area2D$ {
      // Sprite or colored box
      if let asset = config.spriteAsset, let animation = config.spriteAnimation {
        AseSprite$(path: asset)
          .autoplay(animation)
      } else {
        ColorBox$()
          .size(config.size)
          .color(config.color ?? defaultColor)
          .position(-config.size / 2)
      }

      CollisionShape2D$()
        .shape(RectangleShape2D(size: config.size))
        .position(.zero)
    }
    .position(startPosition)
    .rotation(Double(atan2(direction.y, direction.x)))
    .collisionLayer(projectileLayer)
    .collisionMask(targetMask)
    .monitorable(true)
    .monitoring(true)
    .onSignal(\.areaEntered) { node, area in
      guard let area else { return }
      let targetId = Int(area.getInstanceId())
      let hitPos = node.globalPosition
      ActorEvent.projectileHitTarget(
        actorId: sourceActorId,
        targetId: targetId,
        position: hitPos,
        damage: config.damage,
        knockback: config.knockback,
        direction: direction
      ).emit()
      node.queueFree()
    }
    .onSignal(\.bodyEntered) { node, _ in
      // Hit terrain
      ActorEvent.projectileHitWall(actorId: sourceActorId, position: node.globalPosition).emit()
      node.queueFree()
    }
    .onProcess { node, delta in
      vm.lifetime += delta
      if vm.lifetime >= config.lifetime {
        node.queueFree()
        return
      }
      node.position += direction * config.speed * Float(delta)
    }
  }
}

// MARK: - Projectile Spawner

/// Unified projectile spawner for all actors - handles both player and enemy projectiles
/// Listens for ActorEvent.projectileFired and spawns with appropriate collision layers
/// Emits ActorEvent.projectileHitTarget and ActorEvent.projectileHitWall
public struct ActorProjectileSpawner: GView {
  public init() {}

  public var body: some GView {
    Node2D$()
      .onEvent(ActorEvent.self) { node, event in
        switch event {
        case let .projectileFired(actorId, position, direction, config, isPlayerOwned):
          let projectile = ActorProjectileView(
            config: config,
            startPosition: position,
            direction: direction,
            sourceActorId: actorId,
            isPlayerOwned: isPlayerOwned
          )
          node.addChild(node: projectile.toNode())
        default:
          break
        }
      }
  }
}
