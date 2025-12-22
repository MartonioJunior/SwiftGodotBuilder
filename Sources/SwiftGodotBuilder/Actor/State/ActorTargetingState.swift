import Foundation
import SwiftGodot

/// Targeting capability state for actors that track targets
public class ActorTargetingState {
  // MARK: - Detected Targets

  /// Weak references to detected hurtbox areas to prevent retaining freed nodes
  private var weakAreas: [Weak<Area2D>] = []

  /// All valid hurtbox areas currently inside the targetbox.
  /// Automatically filters out freed or queued-for-deletion areas.
  public var detectedAreas: [Area2D] {
    // Clean up stale references and return valid ones
    weakAreas.removeAll { $0.value == nil || $0.value!.isQueuedForDeletion() }
    return weakAreas.compactMap { $0.value }
  }

  /// The closest detected target area
  public var closestTarget: Area2D? {
    detectedAreas.first
  }

  // MARK: - Computed Properties

  /// Current closest target's position (nil if no targets detected)
  public var targetPosition: Vector2? {
    closestTarget?.globalPosition
  }

  /// Distance to closest target (nil if no targets)
  public func distanceTo(_ actorNode: Node2D?) -> Float? {
    guard let targetPos = targetPosition, let actorPos = actorNode?.globalPosition else { return nil }
    return Float(actorPos.distanceTo(targetPos))
  }

  // MARK: - Initialization

  public init() {}

  // MARK: - Target Management

  /// Add a detected target and sort by distance
  public func addTarget(_ area: Area2D, relativeTo actorNode: Node2D?) {
    // Check if already tracking (compare by identity)
    guard !weakAreas.contains(where: { $0.value === area }) else { return }
    weakAreas.append(Weak(area))
    sortByDistance(relativeTo: actorNode)
  }

  /// Remove a target that left the detection area
  public func removeTarget(_ area: Area2D) {
    weakAreas.removeAll { $0.value === area }
  }

  /// Sort targets by distance to actor
  public func sortByDistance(relativeTo actorNode: Node2D?) {
    guard let actorPos = actorNode?.globalPosition else { return }
    // Filter out invalid areas during sort
    weakAreas.removeAll { $0.value == nil || $0.value!.isQueuedForDeletion() }
    weakAreas.sort { a, b in
      guard let areaA = a.value, let areaB = b.value else { return false }
      let distA = actorPos.distanceTo(areaA.globalPosition)
      let distB = actorPos.distanceTo(areaB.globalPosition)
      return distA < distB
    }
  }

  // MARK: - Reset (for pooling)

  /// Resets state to initial values for reuse from pool
  public func reset() {
    weakAreas.removeAll()
  }
}
