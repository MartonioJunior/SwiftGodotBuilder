import Foundation
import SwiftGodot

// MARK: - Actor

/// A composable actor view with role-based modifiers.
public struct Actor<Content: GView, Collision: GView, Hurtbox: GView, Hitbox: GView, Targetbox: GView, Interaction: GView, Collector: GView, Selectbox: GView>: GView {
  let contentBuilder: (ActorState) -> Content

  // Role modifiers
  let collisionBuilder: ((ActorState) -> Collision)?
  let hurtboxBuilder: ((ActorState) -> Hurtbox)?
  let hitboxBuilder: ((ActorState, ActorWeaponState?) -> Hitbox)?
  let targetboxBuilder: ((ActorState) -> Targetbox)?
  let interactionBuilder: ((ActorState) -> Interaction)?
  let collectorBuilder: ((ActorState) -> Collector)?
  let selectboxBuilder: ((ActorState) -> Selectbox)?

  let state: ActorState

  // Direct node references for high-frequency updates (avoids observation overhead)
  private let hitboxRef = GState<Area2D?>(wrappedValue: nil)

  // MARK: - Initialization

  init(
    _ state: ActorState,
    collisionBuilder: ((ActorState) -> Collision)?,
    hurtboxBuilder: ((ActorState) -> Hurtbox)?,
    hitboxBuilder: ((ActorState, ActorWeaponState?) -> Hitbox)?,
    targetboxBuilder: ((ActorState) -> Targetbox)?,
    interactionBuilder: ((ActorState) -> Interaction)?,
    collectorBuilder: ((ActorState) -> Collector)?,
    selectboxBuilder: ((ActorState) -> Selectbox)?,
    @GViewBuilder content: @escaping (ActorState) -> Content
  ) {
    self.collisionBuilder = collisionBuilder
    self.hurtboxBuilder = hurtboxBuilder
    self.hitboxBuilder = hitboxBuilder
    self.targetboxBuilder = targetboxBuilder
    self.interactionBuilder = interactionBuilder
    self.collectorBuilder = collectorBuilder
    self.selectboxBuilder = selectboxBuilder
    contentBuilder = content
    self.state = state
  }

  // MARK: - Body

  public var body: some GView {
    CharacterBody2D$ {
      // Collision shape (terrain collision)
      if let builder = collisionBuilder {
        builder(state)
      }

      // Hurtbox (can receive damage)
      if let builder = hurtboxBuilder {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(state.isPlayer ? .theta : .iota)
        .collisionMask(state.isPlayer ? .kappa : .delta)
        .onEvent(ActorEvent.self) { node, event in
          let nodeId = Int(node.getInstanceId())
          switch event {
          case let .meleeHitTarget(actorId, targetId, damage, knockbackAmount, _, direction):
            // Skip self-damage
            if targetId == nodeId, actorId != state.id {
              let knockback = direction * knockbackAmount
              if let onHurt = state.onHurt {
                onHurt(state, damage, knockback)
              } else {
                state.takeDamage(damage, knockback: knockback)
              }
            }
          case let .projectileHitTarget(actorId, targetId, _, damage, knockbackAmount, direction):
            // Skip self-damage
            if targetId == nodeId, actorId != state.id {
              let knockback = direction * knockbackAmount
              if let onHurt = state.onHurt {
                onHurt(state, damage, knockback)
              } else {
                state.takeDamage(damage, knockback: knockback)
              }
            }
          default:
            break
          }
        }
      }

      // Hitbox (can deal damage - only active during attack, flips with facing)
      if let builder = hitboxBuilder, let weapon = state.weapon {
        Area2D$ {
          builder(state, weapon)
        }
        .collisionLayer(state.isPlayer ? .delta : .kappa)
        .collisionMask(state.isPlayer ? .iota : [.theta, .iota])
        .monitoring(weapon.hitboxActive)
        .monitorable(weapon.hitboxActive)
        .ref(hitboxRef) // Scale updated directly in physics loop to avoid observation overhead
        .onSignal(\.areaEntered) { node, area in
          guard let area, let weaponState = state.weapon, weaponState.hitboxActive else { return }
          guard let melee = weaponState.currentMelee else { return }
          let targetId = Int(area.getInstanceId())
          let hitPos = (node.globalPosition + area.globalPosition) / 2.0
          let direction = Vector2(x: state.facing.sign, y: 0)
          ActorEvent.meleeHitTarget(
            actorId: state.id,
            targetId: targetId,
            damage: melee.damage,
            knockback: melee.knockback,
            position: hitPos,
            direction: direction
          ).emit()

          // Call onHit callback
          state.onHit?(state, targetId, melee.damage)
        }
      }

      // Targetbox (scans for targets)
      if let builder = targetboxBuilder, let targeting = state.targeting {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(.zero)
        .collisionMask(state.isPlayer ? .iota : .theta)
        .onSignal(\.areaEntered) { _, area in
          guard let area else { return }
          let hadTargets = targeting.closestTarget != nil
          targeting.addTarget(area, relativeTo: state.node)
          // Call onAcquiredTarget if we just got our first target
          if !hadTargets, targeting.closestTarget != nil {
            state.onAcquiredTarget?(state, area)
          }
        }
        .onSignal(\.areaExited) { _, area in
          guard let area else { return }
          let hadTargets = targeting.closestTarget != nil
          targeting.removeTarget(area)
          // Call onLostAllTargets if we just lost our last target
          if hadTargets, targeting.closestTarget == nil {
            state.onLostAllTargets?(state)
          }
        }
      }

      // Interaction area
      if let builder = interactionBuilder {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(.eta)
        .collisionMask(.eta)
        .onSignal(\.areaEntered) { _, area in
          guard let area else { return }
          // Find the other area's CharacterBody2D ancestor
          if let otherBody: CharacterBody2D = area.getParents().first(where: { $0 is CharacterBody2D }) as? CharacterBody2D {
            let otherBodyId = Int(otherBody.getInstanceId())
            ActorEvent.interactorEntered(actorId: state.id, interactorId: otherBodyId).emit()
          }
        }
        .onSignal(\.areaExited) { _, area in
          guard let area else { return }
          if let otherBody: CharacterBody2D = area.getParents().first(where: { $0 is CharacterBody2D }) as? CharacterBody2D {
            let otherBodyId = Int(otherBody.getInstanceId())
            ActorEvent.interactorExited(actorId: state.id, interactorId: otherBodyId).emit()
          }
        }
        .onEvent(ActorEvent.self) { _, event in
          switch event {
          case let .interacted(actorId, _) where actorId == state.id:
            // If we have dialog capability, try to trigger it
            state.dialog?.tryTriggerDialog(actorState: state)
          case let .interactorEntered(actorId, interactorId):
            // Check if this event is targeting our CharacterBody2D
            if let myBodyId = state.node?.getInstanceId(), interactorId == Int(myBodyId) {
              if !state.nearbyInteractorIds.contains(actorId) {
                state.nearbyInteractorIds.append(actorId)
              }
            }
          case let .interactorExited(actorId, interactorId):
            if let myBodyId = state.node?.getInstanceId(), interactorId == Int(myBodyId) {
              state.nearbyInteractorIds.removeAll { $0 == actorId }
            }
          default:
            break
          }
        }
      }

      // Collector area (detects pickups on .lambda layer)
      if let builder = collectorBuilder {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(.mu)
        .collisionMask(.lambda)
      }

      // Selectbox (can be selected by player)
      if let builder = selectboxBuilder, state.selection != nil {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(.nu)
        .collisionMask(.zero)
        .monitorable(true)
        .monitoring(false)
      }

      // User content
      contentBuilder(state)
    }
    // Actor physics collision: only collide with terrain (alpha), not other actors
    .collisionLayer(state.isPlayer ? .beta : .gamma)
    .collisionMask(.alpha)
    .floorSnapLength(4)
    .onReady { body in
      state.node = body
    }
    .onPhysicsProcess { _, delta in
      guard let body = state.node else { return }

      // Skip processing when dying
      if let defense = state.defense, defense.isDying {
        if !state.isPlayer {
          body.visible = false
          // Pooled actors are released by ActorPool listening for ActorEvent.died
          // Non-pooled actors are freed immediately
          if !state.isPooled {
            Engine.onNextFrame {
              body.queueFree()
            }
          }
        }
        return
      }

      // Update capability timers
      state.updateTimers(delta)

      // Process behavior machine (AI) - before physics so behaviors can set input
      state.processBehaviorMachine(delta)

      // Process physics if configured
      state.physics?.process(body: body, delta: delta, coreState: state)

      // Process weapon if configured
      state.weapon?.process(body: body, delta: delta, coreState: state)

      // Update hitbox directly (avoids observation overhead)
      if let hitbox = hitboxRef.wrappedValue {
        hitbox.scale = state.facingScale
        let isActive = state.weapon?.hitboxActive ?? false
        hitbox.monitoring = isActive
        hitbox.monitorable = isActive
      }
    }
  }
}

// MARK: - Public Convenience Init

public extension Actor where
  Collision == EmptyGView,
  Hurtbox == EmptyGView,
  Hitbox == EmptyGView,
  Targetbox == EmptyGView,
  Interaction == EmptyGView,
  Collector == EmptyGView,
  Selectbox == EmptyGView
{
  init(
    _ state: ActorState,
    @GViewBuilder content: @escaping (ActorState) -> Content
  ) {
    self.init(
      state,
      collisionBuilder: nil,
      hurtboxBuilder: nil,
      hitboxBuilder: nil,
      targetboxBuilder: nil,
      interactionBuilder: nil,
      collectorBuilder: nil,
      selectboxBuilder: nil,
      content: content
    )
  }

  init(
    @GViewBuilder content: @escaping (ActorState) -> Content
  ) {
    self.init(ActorState(), content: content)
  }
}
