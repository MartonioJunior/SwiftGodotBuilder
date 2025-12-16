import SwiftGodotBuilder

/// Additional physics layers for Chapter27's HitBox/HurtBox combat system
/// (terrain, player, collectible, projectile, hazard, interaction already defined in Chapter24)
extension Physics2DLayer {
  /// Layer 8: Player hurtbox - receives damage from enemies
  static let playerHurtbox = theta

  /// Layer 9: Enemy hurtbox - receives damage from player attacks
  static let enemyHurtbox = iota

  /// Layer 10: Enemy attacks (touch damage, projectiles) - monitors player hurtbox
  static let enemyAttack = kappa

  /// Layer 4: Player attacks (hitbox) - monitors enemy hurtboxes
  static let playerAttack = delta
}

extension Chapter27 {
  /// Shared collision layers config for all actors
  static let actorCollisionLayers = ActorCollisionLayers(
    player: .player,
    enemyHurtbox: .enemyHurtbox,
    playerHurtbox: .playerHurtbox,
    enemyAttack: .enemyAttack,
    playerAttack: .playerAttack,
    terrain: .terrain,
    collectible: .collectible,
    interaction: .interaction
  )
}
