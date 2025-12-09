import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// Attack hitbox that uses weapon config for size/position and attack phase for timing
  /// Uses bottom-center origin (parent CharacterBody2D has feet at origin)
  struct AttackHitboxView: GView {
    let player: ObservableState<PlayerState>
    let collisionSize: Vector2

    var playerState: PlayerState { player.wrappedValue }
    var hitboxSize: Vector2 { playerState.weaponConfig.hitboxSize }
    var hitboxOffset: Float { playerState.weaponConfig.hitboxOffset }

    func calculatePosition(for facing: Facing, config: WeaponConfig) -> Vector2 {
      // Bottom-center origin: x=0 is center, y=0 is feet
      // Hitbox should be at player's horizontal edge, vertically centered on body
      let xOffset = facing.isRight ? config.hitboxOffset : -config.hitboxOffset - config.hitboxSize.x
      let yOffset = -collisionSize.y / 2 - config.hitboxSize.y / 2 // Center of body
      return [xOffset, yOffset]
    }

    var body: some GView {
      Area2D$ {
        CollisionShape2D$()
          .shape(RectangleShape2D(size: hitboxSize))
          .position([hitboxSize.x / 2, hitboxSize.y / 2])
      }
      .position(calculatePosition(for: playerState.facing, config: playerState.weaponConfig))
      .collisionLayer(.combat)
      .collisionMask(0)
      .processMode(playerState.attackPhase.hitboxActive ? .inherit : .disabled)
      .visible(playerState.attackPhase.hitboxActive)
      .watch(player, \.facing) { node, newFacing in
        node.position = calculatePosition(for: newFacing, config: playerState.weaponConfig)
      }
      .watch(player, \.attackPhase) { node, phase in
        node.processMode = phase.hitboxActive ? .inherit : .disabled
        node.visible = phase.hitboxActive
      }
      .watch(player, \.currentMeleeWeapon) { node, _ in
        // When weapon changes, update position and size
        node.position = calculatePosition(for: playerState.facing, config: playerState.weaponConfig)
      }
    }
  }
}
