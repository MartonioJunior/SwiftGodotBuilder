import Foundation
import SwiftGodot

// MARK: - Actor

/// A composable actor view with role-based modifiers.
public struct Actor<Content: GView, Collision: GView, Hurtbox: GView, Hitbox: GView, Targetbox: GView, Interaction: GView, Detection: GView, Collector: GView>: GView {
  let contentBuilder: (ObservableState<ActorState>) -> Content

  // Role modifiers
  let collisionBuilder: ((ActorState) -> Collision)?
  let hurtboxBuilder: ((ActorState) -> Hurtbox)?
  let hitboxBuilder: ((ActorState, ActorWeaponState?) -> Hitbox)?
  let targetboxBuilder: ((ActorState) -> Targetbox)?
  let interactionBuilder: ((ActorState) -> Interaction)?
  let detectionBuilder: ((ActorState) -> Detection)?
  let collectorBuilder: ((ActorState) -> Collector)?

  @ObservableState var state: ActorState

  // MARK: - Initialization

  init(
    _ state: ActorState,
    collisionBuilder: ((ActorState) -> Collision)?,
    hurtboxBuilder: ((ActorState) -> Hurtbox)?,
    hitboxBuilder: ((ActorState, ActorWeaponState?) -> Hitbox)?,
    targetboxBuilder: ((ActorState) -> Targetbox)?,
    interactionBuilder: ((ActorState) -> Interaction)?,
    detectionBuilder: ((ActorState) -> Detection)?,
    collectorBuilder: ((ActorState) -> Collector)?,
    @GViewBuilder content: @escaping (ObservableState<ActorState>) -> Content
  ) {
    self.collisionBuilder = collisionBuilder
    self.hurtboxBuilder = hurtboxBuilder
    self.hitboxBuilder = hitboxBuilder
    self.targetboxBuilder = targetboxBuilder
    self.interactionBuilder = interactionBuilder
    self.detectionBuilder = detectionBuilder
    self.collectorBuilder = collectorBuilder
    contentBuilder = content
    _state = ObservableState(wrappedValue: state)
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
          case let .meleeHitTarget(_, targetId, damage, knockbackAmount, _, direction):
            if targetId == nodeId {
              let knockback = direction * knockbackAmount
              state.takeDamage(damage, knockback: knockback)
            }
          case let .projectileHitTarget(_, targetId, _, damage, knockbackAmount, direction):
            if targetId == nodeId {
              let knockback = direction * knockbackAmount
              state.takeDamage(damage, knockback: knockback)
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
        .collisionMask(state.isPlayer ? .iota : .theta)
        .monitoring(weapon.hitboxActive)
        .monitorable(weapon.hitboxActive)
        .scale($state.facingScale)
        .onSignal(\.areaEntered) { node, area in
          guard let area, let weaponState = state.weapon, weaponState.hitboxActive else { return }
          guard let melee = weaponState.currentMelee else { return }
          let targetId = Int(area.getInstanceId())
          let hitPos = (node.globalPosition + area.globalPosition) / 2
          let direction = Vector2(x: state.facing.sign, y: 0)
          ActorEvent.meleeHitTarget(
            actorId: state.id,
            targetId: targetId,
            damage: melee.damage,
            knockback: melee.knockback,
            position: hitPos,
            direction: direction
          ).emit()
        }
        .watch($state, \.weapon?.hitboxActive) { (node: Area2D, active) in
          Engine.onNextFrame {
            let isActive = active ?? false
            node.monitoring = isActive
            node.monitorable = isActive
          }
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
          targeting.addTarget(area, relativeTo: state.node)
        }
        .onSignal(\.areaExited) { _, area in
          guard let area else { return }
          targeting.removeTarget(area)
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

      // Detection area
      if let builder = detectionBuilder {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(.zero)
        .collisionMask(.eta)
      }

      // Collector area
      if let builder = collectorBuilder {
        Area2D$ {
          builder(state)
        }
        .collisionLayer(.zero)
        .collisionMask(.gamma)
      }

      // User content - pass ObservableState for reactive bindings
      contentBuilder($state)
    }
    // Actor physics collision: only collide with terrain (alpha), not other actors
    .collisionLayer(state.isPlayer ? .beta : .gamma)
    .collisionMask(.alpha)
    .floorSnapLength(4)
    .onReady { node in
      guard let body = node as? CharacterBody2D else { return }
      state.node = body
    }
    .onPhysicsProcess { _, delta in
      guard let body = state.node else { return }

      // Skip processing when dying
      if let defense = state.defense, defense.isDying {
        if !state.isPlayer {
          body.visible = false
          Engine.onNextFrame {
            body.queueFree()
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
  Detection == EmptyGView,
  Collector == EmptyGView
{
  init(
    _ state: ActorState,
    @GViewBuilder content: @escaping (ObservableState<ActorState>) -> Content
  ) {
    self.init(
      state,
      collisionBuilder: nil,
      hurtboxBuilder: nil,
      hitboxBuilder: nil,
      targetboxBuilder: nil,
      interactionBuilder: nil,
      detectionBuilder: nil,
      collectorBuilder: nil,
      content: content
    )
  }
}
