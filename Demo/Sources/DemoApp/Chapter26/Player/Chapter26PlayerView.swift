import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct PlayerView: GView {
    let entity: LDEntity
    let level: LDLevel
    let player: ObservableState<PlayerState>
    let isActive: State<Bool>
    let cameraOffset: State<Vector2>

    let wc = WorldConfig()

    var playerState: PlayerState { player.wrappedValue }
    var levelWidth: Float { Float(level.pxWid) }
    var levelHeight: Float { Float(level.pxHei) }
    var spriteSize: Vector2 { entity.size }
    var collisionSize: Vector2 { [spriteSize.x - 2, spriteSize.y] }

    var body: some GView {
      CharacterBody2D$ {
        PlayerCamera(
          player: player,
          levelWidth: levelWidth,
          levelHeight: levelHeight,
          cameraOffset: cameraOffset
        )

        AseSprite$(path: "Hero")
          .watch(player, \.animationName) { sprite, animName in
            guard sprite.spriteFrames != nil else { return }
            sprite.play(animName)
          }
          .watch(player, \.facing) { sprite, facing in
            sprite.flipH = facing == .left
          }
          .watch(player, \.spriteModulate) { sprite, color in
            sprite.modulate = color
          }
          .watch(player, \.playerScale) { node, scale in
            node.scale = scale
          }
          .watch(player, \.playerRotation) { node, rotation in
            node.rotation = Double(rotation)
          }
          .position([0, -spriteSize.y / 2])

        // Physics collision shape (bottom-center origin, shrinks when crouching)
        CollisionShape2D$()
          .shape(RectangleShape2D(size: collisionSize))
          .position([0, -collisionSize.y / 2])
          .watch(player, \.overlay) { node, overlay in
            let crouching = overlay.contains(.crouching)
            let height = crouching ? collisionSize.y / 2 : collisionSize.y
            node.shape = RectangleShape2D(w: collisionSize.x, h: height)
            node.position = [0, -height / 2]
          }

        // Interaction area (centered on player)
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: 12, h: 12))
            .position([0, -collisionSize.y / 2])
        }
        .collisionLayer(.interaction)

        // Attack hitbox - uses weapon config for size/position
        AttackHitboxView(
          player: player,
          collisionSize: collisionSize
        )
      }
      .collisionLayer(.player)
      .collisionMask(.terrain)
      .floorSnapLength(4)
      .watch(player, \.position) { node, pos in
        node.position = pos
      }
      .watch(player, \.velocity) { body, vel in
        body.velocity = vel
      }
      .onReady { node in
        playerState.initializeSpawn(from: entity, levelIid: level.iid, collisionHeight: collisionSize.y)
        node.position = playerState.position
      }
      .onEvent(GameEvent.self) { _, event in
        playerState.handleEvent(event)
      }
      .onProcess { body, delta in
        guard isActive.wrappedValue else { return }
        playerState.update(body: body, gravity: wc.gravity, collisionSize: collisionSize, levelWidth: levelWidth, delta: delta)
        playerState.updateTimers(delta)
        playerState.updateVisualEffects(delta)
      }
    }
  }
}
