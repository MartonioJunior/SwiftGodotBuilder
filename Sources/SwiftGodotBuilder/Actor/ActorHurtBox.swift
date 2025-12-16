import SwiftGodot

/// Hurtbox for actors - receives damage from attacks
/// Listens for meleeHit and projectileHitTarget events, applies damage when targetId matches
public struct ActorHurtBox: GView {
  public let state: ObservableState<ActorState>

  /// Physics layer for the hurtbox (should be player or enemy hurtbox)
  public var collisionLayer: Physics2DLayer = .theta

  private var actor: ActorState { state.wrappedValue }
  private var size: Vector2 { actor.collisionConfig.size(for: actor.collisionSize, type: .hurtbox) }

  public init(
    state: ObservableState<ActorState>,
    collisionLayer: Physics2DLayer = .theta
  ) {
    self.state = state
    self.collisionLayer = collisionLayer
  }

  public var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: size))
        .position(actor.collisionOffset)
        .watch(state, \.isDying) { cs, isDying in
          Engine.onNextFrame { cs.disabled = isDying }
        }
    }
    .collisionLayer(collisionLayer)
    .collisionMask(.none)
    .monitorable(true)
    .monitoring(false)
    .onReady { _ in
      ActorEvent.spawned(actorId: actor.id).emit()
    }
    .onEvent(ActorEvent.self) { node, event in
      let myInstanceId = Int(node.getInstanceId())
      switch event {
      case let .meleeHit(_, targetId, position, damage) where targetId == myInstanceId:
        actor.takeDamage(damage, from: position)
      case let .projectileHitTarget(_, targetId, position, damage) where targetId == myInstanceId:
        actor.takeDamage(damage, from: position)
      case let .dealtDamage(_, targetId, damage) where targetId == myInstanceId:
        actor.takeDamage(damage, from: actor.position)
      default:
        break
      }
    }
  }
}
