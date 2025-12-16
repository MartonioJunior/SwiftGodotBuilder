import Foundation
import SwiftGodot

// MARK: - Projectile State

/// Mutable state for a projectile
final class ProjectileState {
  var lifetime: Double = 0
}

// MARK: - Projectile View

/// A single projectile fired by an actor
public struct ActorProjectileView: GView {
  public let config: ActorRangedConfig
  public let startPosition: Vector2
  public let direction: Vector2
  public let sourceActorId: Int
  public let projectileLayer: Physics2DLayer
  public let targetLayer: Physics2DLayer
  public let terrainLayer: Physics2DLayer

  private let state = ProjectileState()

  public init(
    config: ActorRangedConfig,
    startPosition: Vector2,
    direction: Vector2,
    sourceActorId: Int,
    projectileLayer: Physics2DLayer,
    targetLayer: Physics2DLayer,
    terrainLayer: Physics2DLayer
  ) {
    self.config = config
    self.startPosition = startPosition
    self.direction = direction
    self.sourceActorId = sourceActorId
    self.projectileLayer = projectileLayer
    self.targetLayer = targetLayer
    self.terrainLayer = terrainLayer
  }

  private var defaultColor: Color {
    config.isPlayerOwned ? Color(code: "#AAAAFF") : Color(code: "#FF4444")
  }

  public var body: some GView {
    Area2D$ {
      // Sprite or colored box - both centered at origin
      if let asset = config.spriteAsset, let animation = config.spriteAnimation {
        AseSprite$(path: asset)
          .autoplay(animation)
      } else {
        ColorBox$()
          .size(config.size)
          .color(config.color ?? defaultColor)
      }

      CollisionShape2D$()
        .shape(RectangleShape2D(size: config.size))
        .position(config.size / 2)
    }
    .position(startPosition)
    .rotation(Double(atan2(direction.y, direction.x)))
    .collisionLayer(projectileLayer)
    .collisionMask(Physics2DLayer([targetLayer, terrainLayer]))
    .monitorable(false)
    .monitoring(true)
    .onSignal(\.areaEntered) { [sourceActorId, config] node, area in
      guard let area else { return }
      let targetId = Int(area.getInstanceId())
      let hitPos = node.globalPosition
      ActorEvent.projectileHitTarget(actorId: sourceActorId, targetId: targetId, position: hitPos, damage: config.damage).emit()
      node.queueFree()
    }
    .onSignal(\.bodyEntered) { [sourceActorId] node, _ in
      // Hit terrain
      ActorEvent.projectileHitWall(actorId: sourceActorId, position: node.globalPosition).emit()
      node.queueFree()
    }
    .onProcess { node, delta in
      state.lifetime += delta
      if state.lifetime >= config.lifetime {
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
  public let collisionLayers: ActorCollisionLayers

  public init(collisionLayers: ActorCollisionLayers) {
    self.collisionLayers = collisionLayers
  }

  public var body: some GView {
    Node2D$()
      .onEvent(ActorEvent.self) { [collisionLayers] node, event in
        switch event {
        case let .projectileFired(actorId, position, direction, config):
          // Player projectiles use playerAttack layer and target enemyHurtbox
          // Enemy projectiles use enemyAttack layer and target playerHurtbox
          let projectileLayer = config.isPlayerOwned ? collisionLayers.playerAttack : collisionLayers.enemyAttack
          let targetLayer = config.isPlayerOwned ? collisionLayers.enemyHurtbox : collisionLayers.playerHurtbox

          let projectile = ActorProjectileView(
            config: config,
            startPosition: position,
            direction: direction,
            sourceActorId: actorId,
            projectileLayer: projectileLayer,
            targetLayer: targetLayer,
            terrainLayer: collisionLayers.terrain
          )
          node.addChild(node: projectile.toNode())
        default:
          break
        }
      }
  }
}
