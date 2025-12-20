import Foundation
import SwiftGodot

/// Targeting capability state for actors that track targets
@Observable
public class ActorTargetingState {
  // MARK: - Detected Targets

  /// All hurtbox areas currently inside the targetbox
  public var detectedAreas: [Area2D] = []

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
    guard !detectedAreas.contains(where: { $0 == area }) else { return }
    detectedAreas.append(area)
    sortByDistance(relativeTo: actorNode)
  }

  /// Remove a target that left the detection area
  public func removeTarget(_ area: Area2D) {
    detectedAreas.removeAll { $0 == area }
  }

  /// Sort targets by distance to actor
  public func sortByDistance(relativeTo actorNode: Node2D?) {
    guard let actorPos = actorNode?.globalPosition else { return }
    detectedAreas.sort { a, b in
      let distA = actorPos.distanceTo(a.globalPosition)
      let distB = actorPos.distanceTo(b.globalPosition)
      return distA < distB
    }
  }
}
