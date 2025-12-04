import SwiftGodotBuilder

/// Semantic aliases for physics layers used in Chapter24
extension Physics2DLayer {
  /// Layer 1: Terrain/walls/platforms that block movement
  static let terrain = alpha

  /// Layer 2: Player's physical body for collisions
  static let player = beta

  /// Layer 3: Collectibles and NPCs
  static let collectible = gamma

  /// Layer 4: Player attacks and enemy damage areas
  static let combat = delta

  /// Layer 5: Enemy projectiles and triggers
  static let projectile = epsilon

  /// Layer 6: Environmental hazards (spikes, crushers)
  static let hazard = zeta

  /// Layer 7: Player's interaction detection area
  static let interaction = eta
}
