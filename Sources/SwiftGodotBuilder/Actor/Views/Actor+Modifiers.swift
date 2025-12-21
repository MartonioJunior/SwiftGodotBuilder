import Foundation
import SwiftGodot

public extension Actor {
  /// Add terrain collision shape
  func collision<NewCollision: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewCollision
  ) -> Actor<Content, NewCollision, Hurtbox, Hitbox, Targetbox, Interaction, Collector> {
    Actor<Content, NewCollision, Hurtbox, Hitbox, Targetbox, Interaction, Collector>(
      state,
      collisionBuilder: builder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      content: contentBuilder
    )
  }

  /// Add hurtbox (can receive damage)
  func hurtbox<NewHurtbox: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewHurtbox
  ) -> Actor<Content, Collision, NewHurtbox, Hitbox, Targetbox, Interaction, Collector> {
    Actor<Content, Collision, NewHurtbox, Hitbox, Targetbox, Interaction, Collector>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: builder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      content: contentBuilder
    )
  }

  /// Add hitbox (can deal damage)
  func hitbox<NewHitbox: GView>(
    @GViewBuilder _ builder: @escaping (ActorState, ActorWeaponState?) -> NewHitbox
  ) -> Actor<Content, Collision, Hurtbox, NewHitbox, Targetbox, Interaction, Collector> {
    Actor<Content, Collision, Hurtbox, NewHitbox, Targetbox, Interaction, Collector>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: builder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      content: contentBuilder
    )
  }

  /// Add targetbox (scans for targets) - automatically enables targeting capability
  func targetbox<NewTargetbox: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewTargetbox
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, NewTargetbox, Interaction, Collector> {
    // Auto-enable targeting when targetbox is added
    if state.targeting == nil {
      state.targeting = ActorTargetingState()
    }
    return Actor<Content, Collision, Hurtbox, Hitbox, NewTargetbox, Interaction, Collector>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: builder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      content: contentBuilder
    )
  }

  /// Add interaction area
  func interaction<NewInteraction: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewInteraction
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, NewInteraction, Collector> {
    Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, NewInteraction, Collector>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: builder,
      collectorBuilder: collectorBuilder,
      content: contentBuilder
    )
  }

  /// Add collector area (can pick up items)
  func collector<NewCollector: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewCollector
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, Interaction, NewCollector> {
    Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, Interaction, NewCollector>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: builder,
      content: contentBuilder
    )
  }

  /// Configure physics capability
  func physics(_ config: ActorPhysicsConfig) -> Self {
    state.physics = ActorPhysicsState(config: config)
    return self
  }

  /// Configure defense capability (health, invincibility)
  func defense(_ config: ActorDefenseConfig) -> Self {
    state.defense = ActorDefenseState(config: config)
    return self
  }

  /// Configure attack capabilities with weapons array
  func attacks(_ weapons: [ActorWeaponConfig]) -> Self {
    state.weapon = ActorWeaponState(weapons: weapons)
    return self
  }

  /// Mark this actor as the player
  func isPlayer() -> Self {
    state.isPlayer = true
    return self
  }

  /// Configure behavior machine for AI-controlled actors
  func behavior<S: Hashable & Sendable>(_ machine: BehaviorMachine<S>) -> Self {
    state.behaviorMachine = AnyBehaviorMachine(machine)
    return self
  }

  /// Configure behavior machine with inline DSL
  func behavior<S: Hashable & Sendable>(
    _ initial: S,
    @BehaviorMachineBuilder<S> _ builder: () -> [BehaviorState<S>]
  ) -> Self {
    state.behaviorMachine = AnyBehaviorMachine(BehaviorMachine(initial: initial, builder))
    return self
  }

  /// Configure behavior machine with string-based states
  func behavior(
    initial: String,
    @BehaviorMachineBuilder<String> _ builder: () -> [BehaviorState<String>]
  ) -> Self {
    state.behaviorMachine = AnyBehaviorMachine(BehaviorMachine(initial: initial, builder))
    return self
  }

  /// Configure dialog capability - provides dialog when actor is interacted with
  /// The closure receives actor state and dialog state, returns a DialogDefinition or nil
  func dialog(_ factory: @escaping (ActorState, DialogState) -> DialogDefinition?) -> Self {
    state.dialog = ActorDialogState(dialogFactory: factory)
    return self
  }

  // MARK: - Combat Callbacks

  /// Called when this actor takes damage. Receives (damage, knockback).
  /// If set, replaces default damage handling - call `state.takeDamage` manually if needed.
  func onHurt(_ handler: @escaping (Int, Vector2) -> Void) -> Self {
    state.onHurt = handler
    return self
  }

  /// Called when this actor hits a target. Receives (targetId, damage).
  func onHit(_ handler: @escaping (Int, Int) -> Void) -> Self {
    state.onHit = handler
    return self
  }

  /// Called when this actor dies.
  func onDeath(_ handler: @escaping () -> Void) -> Self {
    state.onDeath = handler
    return self
  }

  /// Called when targeting acquires a new target.
  func onAcquiredTarget(_ handler: @escaping (Area2D) -> Void) -> Self {
    state.onAcquiredTarget = handler
    return self
  }

  /// Called when targeting loses all targets.
  func onLostAllTargets(_ handler: @escaping () -> Void) -> Self {
    state.onLostAllTargets = handler
    return self
  }
}
