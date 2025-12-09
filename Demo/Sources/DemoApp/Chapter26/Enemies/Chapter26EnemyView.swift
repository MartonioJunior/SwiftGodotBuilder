import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct EnemyView: GView {
    @ObservableState var state: EnemyState
    let isActive: State<Bool>

    init(entity: LDEntity, isActive: State<Bool>) {
      self._state = ObservableState(wrappedValue: EnemyState(entity: entity))
      self.isActive = isActive
    }

    init(definition: EnemyDefinition, spawnPoint: Vector2, patrolLeft: Float, patrolRight: Float, isActive: State<Bool>) {
      self._state = ObservableState(wrappedValue: EnemyState(definition: definition, spawnPoint: spawnPoint, patrolLeft: patrolLeft, patrolRight: patrolRight))
      self.isActive = isActive
    }

    private var enemy: EnemyState { state }

    var body: some GView {
      Node2D$ {
        AseSprite$(path: "Mobs")
          .centered(false)
          .watch($state, \.direction) { sprite, dir in
            sprite.flipH = dir < 0
          }
          .watch($state, \.animationName) { sprite, anim in
            guard sprite.spriteFrames != nil else { return }
            sprite.play(anim)
          }
          .onReady { sprite in
            sprite.play(enemy.animationName)
          }
          .watchAny($state) { sprite, state in
            if state.isDying {
              let alpha = Float(state.deathTimer / state.deathFadeDuration)
              sprite.modulate = Color(r: 1, g: 1, b: 1, a: alpha)
            } else {
              sprite.modulate = .white
            }
          }

        // Enemy damage area - detects player body and player attacks
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: enemy.size, h: enemy.size))
            .position([enemy.size / 2, enemy.size / 2])
            .watch($state, \.isDying) { cs, isDying in
              Engine.onNextFrame { cs.disabled = isDying }
            }
        }
        .collisionLayer(0)
        .collisionMask([.player, .combat])
        .onSignal(\.bodyEntered) { _, body in
          if !enemy.isDying, body is CharacterBody2D {
            GameEvent.playerHit(damage: enemy.touchDamage, position: enemy.position).emit()
          }
        }
        .onSignal(\.areaEntered) { _, _ in
          if !enemy.isDying {
            let hitPos = enemy.position + [enemy.size / 2, enemy.size / 2]
            GameEvent.meleeHitEnemy(position: hitPos).emit()
            enemy.takeDamage(1)
          }
        }
      }
      .watch($state, \.position) { node, pos in
        node.position = pos
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          enemy.respawn()
        }
      }
      .onProcess { node, delta in
        guard isActive.wrappedValue else { return }

        if enemy.isDying {
          if enemy.updateDeath(delta: delta) {
            node.queueFree()
          }
          return
        }

        enemy.update(delta: delta)
      }
    }
  }
}
