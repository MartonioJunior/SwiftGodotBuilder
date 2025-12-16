import SwiftGodot

// MARK: - Interaction Area

/// Makes an actor detectable by NPCs and other interactables
public struct ActorInteractionArea: GView {
  public let state: ObservableState<ActorState>

  /// Physics layer for interaction detection
  public var interactionLayer: Physics2DLayer = .gamma

  private var actor: ActorState { state.wrappedValue }
  private var size: Vector2 { actor.collisionConfig.size(for: actor.collisionSize, type: .interaction) }

  public init(
    state: ObservableState<ActorState>,
    interactionLayer: Physics2DLayer = .gamma
  ) {
    self.state = state
    self.interactionLayer = interactionLayer
  }

  public var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: size))
        .position(actor.collisionOffset)
    }
    .collisionLayer(interactionLayer)
    .collisionMask(interactionLayer)
  }
}

// MARK: - Interactable Zone

/// Makes an actor interactable by other actors (e.g., player can talk to NPCs)
/// Detects when interactors enter/exit range and handles interaction input
/// Emits ActorEvent.interacted when interaction occurs
public struct ActorInteractableZone: GView {
  public let state: ObservableState<ActorState>

  /// Physics layer for interaction detection
  public var interactionLayer: Physics2DLayer = .gamma

  private var actor: ActorState { state.wrappedValue }

  // Interaction range is wider than collision for easier targeting
  private var interactionSize: Vector2 {
    [actor.collisionSize.x * 3, actor.collisionSize.y + 8]
  }

  public init(
    state: ObservableState<ActorState>,
    interactionLayer: Physics2DLayer = .gamma
  ) {
    self.state = state
    self.interactionLayer = interactionLayer
  }

  public var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: interactionSize))
        .position(actor.collisionOffset)
    }
    .collisionLayer(interactionLayer)
    .collisionMask(interactionLayer)
    .monitorable(true)
    .monitoring(true)
    .onSignal(\.areaEntered) { _, area in
      guard let area else { return }
      let interactorId = Int(area.getInstanceId())
      actor.interactorsInRange.insert(interactorId)
      ActorEvent.interactorEntered(actorId: actor.id, interactorId: interactorId).emit()
    }
    .onSignal(\.areaExited) { _, area in
      guard let area else { return }
      let interactorId = Int(area.getInstanceId())
      actor.interactorsInRange.remove(interactorId)
      ActorEvent.interactorExited(actorId: actor.id, interactorId: interactorId).emit()
    }
    .onProcess { _, _ in
      // Check for interaction input when someone is in range
      guard !actor.interactorsInRange.isEmpty else { return }
      if Action("interact").isJustPressed {
        // Emit interaction event - use first interactor in range
        if let interactorId = actor.interactorsInRange.first {
          ActorEvent.interacted(actorId: actor.id, interactorId: interactorId).emit()
        }
      }
    }
  }
}

// MARK: - Name Label

/// Shows the actor's name when an interactor is in range
public struct ActorNameLabel: GView {
  public let state: ObservableState<ActorState>

  private var actor: ActorState { state.wrappedValue }

  public var labelOffsetY: Double { Double(-actor.collisionSize.y - 12) }

  public init(state: ObservableState<ActorState>) {
    self.state = state
  }

  public var body: some GView {
    Label$()
      .text(actor.displayName ?? "")
      .horizontalAlignment(.center)
      .growHorizontal(.both)
      .offset(top: labelOffsetY, right: 0, bottom: 0, left: 0)
      .onProcess { label, _ in
        label.visible = !actor.interactorsInRange.isEmpty && actor.displayName != nil
      }
  }
}

// MARK: - Collector

/// Item collector component for actors
/// Emits ActorEvent.collected when items are picked up
public struct ActorCollector: GView {
  public let state: ObservableState<ActorState>
  public var weaponState: ObservableState<ActorWeaponState>?

  /// Physics layer for collectibles
  public var collectibleMask: Physics2DLayer = .epsilon

  private var actor: ActorState { state.wrappedValue }
  private var weapons: ActorWeaponState? { weaponState?.wrappedValue }
  private var size: Vector2 { actor.collisionConfig.size(for: actor.collisionSize, type: .collector) }

  public init(
    state: ObservableState<ActorState>,
    weaponState: ObservableState<ActorWeaponState>? = nil,
    collectibleMask: Physics2DLayer = .epsilon
  ) {
    self.state = state
    self.weaponState = weaponState
    self.collectibleMask = collectibleMask
  }

  public var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: size))
        .position(actor.collisionOffset)
    }
    .collisionLayer(.none)
    .collisionMask(collectibleMask)
    .monitoring(true)
    .onSignal(\.areaEntered) { [actor] _, area in
      guard let area else { return }

      // Items encode their type in node name: "Collectible_Sword"
      let nodeName = String(area.name)
      guard nodeName.hasPrefix("Collectible_") else { return }
      let itemId = String(nodeName.dropFirst("Collectible_".count))

      // Add to inventory (emits ActorEvent.collected)
      actor.addItem(itemId)
    }
  }
}
