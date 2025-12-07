import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  /// Attack hitbox that uses weapon config for size/position and attack phase for timing
  struct AttackHitboxView: GView {
    let facing: State<Facing>
    let attackPhase: State<AttackPhase>
    let weaponConfig: WeaponConfig
    let playerSize: Vector2

    let hitboxColor = Color(code: "#FFFFFFCC")

    var hitboxSize: Vector2 { weaponConfig.hitboxSize }
    var hitboxOffset: Float { weaponConfig.hitboxOffset }

    func calculatePosition(for facing: Facing) -> Vector2 {
      let playerCenterX = playerSize.x / 2
      let playerCenterY = playerSize.y / 2
      let xOffset = facing.isRight ? hitboxOffset : -hitboxOffset - hitboxSize.x
      return [playerCenterX + xOffset, playerCenterY - hitboxSize.y / 2]
    }

    var body: some GView {
      Area2D$ {
        // Visual indicator
        ColorBox$()
          .size(hitboxSize)
          .color(hitboxColor)

        // Collision shape centered within hitbox
        CollisionShape2D$()
          .shape(RectangleShape2D(size: hitboxSize))
          .position([hitboxSize.x / 2, hitboxSize.y / 2])
      }
      .position(calculatePosition(for: facing.wrappedValue))
      .collisionLayer(.combat)
      .collisionMask(0)
      .processMode(attackPhase.wrappedValue.hitboxActive ? .inherit : .disabled)
      .visible(attackPhase.wrappedValue.hitboxActive)
      .watch(facing) { node, newFacing in
        node.position = calculatePosition(for: newFacing)
      }
      .watch(attackPhase) { node, phase in
        node.processMode = phase.hitboxActive ? .inherit : .disabled
        node.visible = phase.hitboxActive
      }
    }
  }
}
