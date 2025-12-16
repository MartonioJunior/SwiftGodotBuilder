import SwiftGodot

/// Active hitbox that deals touch damage on contact
/// Emits ActorEvent.dealtDamage when contact occurs
public struct ActorTouchDamage: GView {
  public let state: ObservableState<ActorState>

  /// Physics layer for the attack (should be enemy or player attack)
  public var collisionLayer: Physics2DLayer = .kappa

  /// Physics layer to detect (should be hurtbox of opposite type)
  public var collisionMask: Physics2DLayer = .theta

  private var actor: ActorState { state.wrappedValue }
  private var size: Vector2 { actor.collisionConfig.size(for: actor.collisionSize, type: .touchDamage) }

  public init(
    state: ObservableState<ActorState>,
    collisionLayer: Physics2DLayer = .kappa,
    collisionMask: Physics2DLayer = .theta
  ) {
    self.state = state
    self.collisionLayer = collisionLayer
    self.collisionMask = collisionMask
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
    .collisionMask(collisionMask)
    .monitorable(false)
    .monitoring(true)
    .onSignal(\.areaEntered) { _, area in
      guard !actor.isDying, let area else { return }
      let targetId = Int(area.getInstanceId())
      ActorEvent.dealtDamage(actorId: actor.id, targetId: targetId, damage: actor.combat.touchDamage).emit()
    }
  }
}
