import SwiftGodot

// MARK: - Physics Raycast Helpers

public extension PhysicsDirectSpaceState2D {
  /// Perform a raycast with simplified parameters.
  ///
  /// This is a convenience wrapper around `intersectRay` that handles the
  /// boilerplate of creating `PhysicsRayQueryParameters2D` and exclusion arrays.
  ///
  /// ### Usage:
  /// ```swift
  /// if let spaceState = player.getWorld2d()?.directSpaceState {
  ///   if spaceState.raycast(from: start, to: end, mask: 1, excluding: player) != nil {
  ///     // Something was hit
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - from: The starting point of the ray in world coordinates
  ///   - to: The end point of the ray in world coordinates
  ///   - mask: Collision mask to filter what layers the ray can hit (default: all layers)
  ///   - excluding: Optional collision object to exclude from the raycast (e.g., the caster)
  /// - Returns: The raycast result if something was hit, nil if nothing hit
  func raycast(
    from: Vector2,
    to: Vector2,
    mask: UInt32 = 0xFFFF_FFFF,
    excluding body: CollisionObject2D? = nil
  ) -> IntersectRayResult<Object>? {
    let exclude = TypedArray<RID>()
    if let body {
      exclude.append(body.getRid())
    }
    guard let query = PhysicsRayQueryParameters2D.create(
      from: from,
      to: to,
      collisionMask: mask,
      exclude: exclude
    ) else {
      return nil
    }
    return intersectRay(parameters: query)
  }
}
