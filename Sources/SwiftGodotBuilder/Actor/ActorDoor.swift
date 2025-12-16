import SwiftGodot

// MARK: - Door Events

/// Events for actor door interactions
public enum ActorDoorEvent: EmittableEvent {
  /// Actor entered a door (any actor)
  case actorEnteredDoor(actorId: Int, targetLevelIid: String, targetEntityIid: String, isCrossLevel: Bool)

  /// Actor arrived at door destination (after teleport)
  case actorArrivedAtDoor(actorId: Int, position: Vector2)
}

/// Events emitted by doorway entities
public enum DoorwayEvent: EmittableEvent {
  /// Door was entered (contains target info)
  case entered(levelIid: String, entityIid: String)
}

// MARK: - Door Info

/// Information about a door/portal
public struct DoorInfo: Equatable, Sendable {
  public let targetLevelIid: String
  public let targetEntityIid: String
  public let position: Vector2

  public init(targetLevelIid: String, targetEntityIid: String, position: Vector2) {
    self.targetLevelIid = targetLevelIid
    self.targetEntityIid = targetEntityIid
    self.position = position
  }

  public static func == (lhs: DoorInfo, rhs: DoorInfo) -> Bool {
    lhs.targetLevelIid == rhs.targetLevelIid &&
      lhs.targetEntityIid == rhs.targetEntityIid
  }
}

// MARK: - Door Interaction Component

/// Door interaction component for actors - responds to DoorwayEvent from doors
/// Emits ActorDoorEvent.actorEnteredDoor for cross-level transitions
/// Emits ActorDoorEvent.actorArrivedAtDoor for same-level teleports
public struct ActorDoorInteraction: GView {
  public let state: ObservableState<ActorState>
  public let currentLevelIid: String

  /// Level lookup for resolving door targets (entity IID -> position)
  public let resolveDoorTarget: ((String) -> Vector2?)?

  private var actor: ActorState { state.wrappedValue }

  public init(
    state: ObservableState<ActorState>,
    currentLevelIid: String = "",
    resolveDoorTarget: ((String) -> Vector2?)? = nil
  ) {
    self.state = state
    self.currentLevelIid = currentLevelIid
    self.resolveDoorTarget = resolveDoorTarget
  }

  public var body: some GView {
    // Just listen for door events - DoorwayView handles overlap detection
    Node$()
      .onEvent(DoorwayEvent.self) { _, event in
        switch event {
        case let .entered(levelIid, entityIid):
          enterDoor(targetLevelIid: levelIid, targetEntityIid: entityIid)
        }
      }
  }

  /// Enter a door with the given target
  private func enterDoor(targetLevelIid: String, targetEntityIid: String) {
    let isCrossLevel = !currentLevelIid.isEmpty && !targetLevelIid.isEmpty && targetLevelIid != currentLevelIid

    if isCrossLevel {
      // Cross-level - emit event for game layer to handle
      ActorDoorEvent.actorEnteredDoor(
        actorId: actor.id,
        targetLevelIid: targetLevelIid,
        targetEntityIid: targetEntityIid,
        isCrossLevel: true
      ).emit()
    } else {
      // Same level - teleport directly
      if let targetPosition = resolveDoorTarget?(targetEntityIid) {
        actor.teleportTo(targetPosition)
        ActorDoorEvent.actorArrivedAtDoor(actorId: actor.id, position: targetPosition).emit()
      } else {
        // Fallback: emit event for external handling
        ActorDoorEvent.actorEnteredDoor(
          actorId: actor.id,
          targetLevelIid: targetLevelIid,
          targetEntityIid: targetEntityIid,
          isCrossLevel: false
        ).emit()
      }
    }
  }
}
