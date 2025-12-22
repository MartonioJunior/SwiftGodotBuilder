import Foundation
import SwiftGodot

public extension Actor {
  /// Add terrain collision shape
  func collision<NewCollision: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewCollision
  ) -> Actor<Content, NewCollision, Hurtbox, Hitbox, Targetbox, Interaction, Collector, Selectbox> {
    Actor<Content, NewCollision, Hurtbox, Hitbox, Targetbox, Interaction, Collector, Selectbox>(
      state,
      collisionBuilder: builder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      selectboxBuilder: selectboxBuilder,
      content: contentBuilder
    )
  }

  /// Add hurtbox (can receive damage)
  func hurtbox<NewHurtbox: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewHurtbox
  ) -> Actor<Content, Collision, NewHurtbox, Hitbox, Targetbox, Interaction, Collector, Selectbox> {
    Actor<Content, Collision, NewHurtbox, Hitbox, Targetbox, Interaction, Collector, Selectbox>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: builder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      selectboxBuilder: selectboxBuilder,
      content: contentBuilder
    )
  }

  /// Add hitbox (can deal damage)
  func hitbox<NewHitbox: GView>(
    @GViewBuilder _ builder: @escaping (ActorState, ActorWeaponState?) -> NewHitbox
  ) -> Actor<Content, Collision, Hurtbox, NewHitbox, Targetbox, Interaction, Collector, Selectbox> {
    Actor<Content, Collision, Hurtbox, NewHitbox, Targetbox, Interaction, Collector, Selectbox>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: builder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      selectboxBuilder: selectboxBuilder,
      content: contentBuilder
    )
  }

  /// Add targetbox (scans for targets) - automatically enables targeting capability
  func targetbox<NewTargetbox: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewTargetbox
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, NewTargetbox, Interaction, Collector, Selectbox> {
    // Auto-enable targeting when targetbox is added
    if state.targeting == nil {
      state.targeting = ActorTargetingState()
    }
    return Actor<Content, Collision, Hurtbox, Hitbox, NewTargetbox, Interaction, Collector, Selectbox>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: builder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      selectboxBuilder: selectboxBuilder,
      content: contentBuilder
    )
  }

  /// Add interaction area
  func interaction<NewInteraction: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewInteraction
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, NewInteraction, Collector, Selectbox> {
    Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, NewInteraction, Collector, Selectbox>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: builder,
      collectorBuilder: collectorBuilder,
      selectboxBuilder: selectboxBuilder,
      content: contentBuilder
    )
  }

  /// Add collector area (can pick up items)
  func collector<NewCollector: GView>(
    @GViewBuilder _ builder: @escaping (ActorState) -> NewCollector
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, Interaction, NewCollector, Selectbox> {
    Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, Interaction, NewCollector, Selectbox>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: builder,
      selectboxBuilder: selectboxBuilder,
      content: contentBuilder
    )
  }

  /// Add selectbox (can be selected by player) - automatically enables selection capability
  func selectbox<NewSelectbox: GView>(
    group: String? = nil,
    @GViewBuilder _ builder: @escaping (ActorState) -> NewSelectbox
  ) -> Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, Interaction, Collector, NewSelectbox> {
    // Auto-enable selection when selectbox is added
    if state.selection == nil {
      state.selection = ActorSelectionState(selectionGroup: group)
    }
    return Actor<Content, Collision, Hurtbox, Hitbox, Targetbox, Interaction, Collector, NewSelectbox>(
      state,
      collisionBuilder: collisionBuilder,
      hurtboxBuilder: hurtboxBuilder,
      hitboxBuilder: hitboxBuilder,
      targetboxBuilder: targetboxBuilder,
      interactionBuilder: interactionBuilder,
      collectorBuilder: collectorBuilder,
      selectboxBuilder: builder,
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

  /// Called when this actor takes damage. Receives (actor, damage, knockback).
  /// If set, replaces default damage handling - call `state.takeDamage` manually if needed.
  func onHurt(_ handler: @escaping (ActorState, Int, Vector2) -> Void) -> Self {
    state.onHurt = handler
    return self
  }

  /// Called when this actor hits a target. Receives (actor, targetId, damage).
  func onHit(_ handler: @escaping (ActorState, Int, Int) -> Void) -> Self {
    state.onHit = handler
    return self
  }

  /// Called when this actor dies.
  func onDeath(_ handler: @escaping (ActorState) -> Void) -> Self {
    state.onDeath = handler
    return self
  }

  /// Called when targeting acquires a new target.
  func onAcquiredTarget(_ handler: @escaping (ActorState, Area2D) -> Void) -> Self {
    state.onAcquiredTarget = handler
    return self
  }

  /// Called when targeting loses all targets.
  func onLostAllTargets(_ handler: @escaping (ActorState) -> Void) -> Self {
    state.onLostAllTargets = handler
    return self
  }

  /// Called before an attack starts. Receives weapon index. Return false to cancel.
  func onBeforeAttack(_ handler: @escaping (ActorState, Int) -> Bool) -> Self {
    state.onBeforeAttack = handler
    return self
  }

  /// Called after an attack fires (for ranged) or activates (for melee).
  func onAttack(_ handler: @escaping (ActorState, Int) -> Void) -> Self {
    state.onAttack = handler
    return self
  }
}
