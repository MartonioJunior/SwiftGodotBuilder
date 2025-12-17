import SwiftGodot

/// Melee attack hitbox that uses weapon configuration
public struct ActorWeaponHitbox: GView {
  public let actorState: ObservableState<ActorState>
  public let weaponState: ObservableState<ActorWeaponState>

  /// Physics layer for the attack
  public var attackLayer: Physics2DLayer = .delta // playerAttack

  /// Physics layer to detect (hurtboxes)
  public var targetMask: Physics2DLayer = .iota // enemyHurtbox

  private var actor: ActorState { actorState.wrappedValue }
  private var weapons: ActorWeaponState { weaponState.wrappedValue }

  private var meleeConfig: ActorMeleeConfig? { weapons.currentWeapon?.melee }

  public init(
    actorState: ObservableState<ActorState>,
    weaponState: ObservableState<ActorWeaponState>,
    attackLayer: Physics2DLayer = .delta,
    targetMask: Physics2DLayer = .iota
  ) {
    self.actorState = actorState
    self.weaponState = weaponState
    self.attackLayer = attackLayer
    self.targetMask = targetMask
  }

  private func calculatePosition(for facing: Facing) -> Vector2 {
    guard let config = meleeConfig else { return .zero }
    let xOffset = facing.isRight ? config.hitboxOffset : -config.hitboxOffset - config.hitboxSize.x
    let yOffset = -actor.collisionSize.y / 2 - config.hitboxSize.y / 2
    return [xOffset, yOffset]
  }

  private func hitboxSize() -> Vector2 {
    meleeConfig?.hitboxSize ?? [8, 8]
  }

  public var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: hitboxSize()))
        .position(hitboxSize() / 2)
    }
    .position(calculatePosition(for: actor.facing))
    .collisionLayer(attackLayer)
    .collisionMask(targetMask)
    .monitorable(weapons.phase.hitboxActive)
    .monitoring(weapons.phase.hitboxActive)
    .visible(weapons.phase.hitboxActive)
    .onSignal(\.areaEntered) { node, area in
      guard let area, let config = meleeConfig else { return }
      let targetId = Int(area.getInstanceId())
      let hitPos = (node.globalPosition + area.globalPosition) / 2
      ActorEvent.meleeHit(
        actorId: actor.id,
        targetId: targetId,
        position: hitPos,
        damage: config.damage,
        knockback: config.knockback,
        direction: [actor.facing.sign, 0]
      ).emit()
    }
    .watch(actorState, \.facing) { node, newFacing in
      node.position = calculatePosition(for: newFacing)
    }
    .watch(weaponState, \.currentIndex) { node, _ in
      // Recalculate position when weapon switches
      node.position = calculatePosition(for: actor.facing)
    }
    .watch(weaponState, \.weapons.count) { node, _ in
      // Recalculate position when weapon is picked up
      node.position = calculatePosition(for: actor.facing)
    }
    .watch(weaponState, \.phase) { (node: Area2D, phase) in
      Engine.onNextFrame {
        node.monitoring = phase.hitboxActive
        node.monitorable = phase.hitboxActive
      }
      node.visible = phase.hitboxActive
      // Recalculate position when attack starts to ensure correct placement after reset
      if phase == .startup {
        node.position = calculatePosition(for: actor.facing)
      }
    }
  }
}

// MARK: - Attack Events

/// Events emitted by the attack system
public enum ActorAttackEvent: EmittableEvent {
  case attackStarted(actorId: Int, position: Vector2, facing: Facing)
  case attackHit(actorId: Int, targetId: Int, position: Vector2, damage: Int)
  case attackEnded(actorId: Int)
}
