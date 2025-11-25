import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter17 {
  struct EnemySpawner: GView {
    let enemyType: EnemyType
    let position: Vector2
    let patrolLeft: Float
    let patrolRight: Float
    let gravity: Float
    let respawnDelay: Double = 5.0
    let state: ObservableState<GameViewState>

    @State var enemyAlive = false
    @State var respawnTimer = 0.0
    @State var pulseTimer = 0.0
    @State var enemyNode: Node?

    let palette = Palette()

    var pulseColor: GState<Color> {
      $pulseTimer.computed { timer in
        let alpha = 0.3 + 0.3 * sin(Float(timer * 3))
        let c = palette.enemySpawnerPurple
        return Color(r: c.red, g: c.green, b: c.blue, a: alpha)
      }
    }

    var body: some GView {
      Node2D$ {
        // Visual indicator - pulsing square
        ColorBox$()
          .size([8, 8])
          .color(pulseColor)
          .bind(\.visible, to: $enemyAlive) { !$0 }
      }
      .position(position)
      .onEvent(Event.self) { _, event in
        if case let .enemyKilled(pos) = event {
          // Check if this is our enemy (approximate position match)
          if abs(pos.x - position.x) < 50 && abs(pos.y - position.y) < 50 {
            // Enemy will free itself after death timer - just track state
            enemyNode = nil
            enemyAlive = false
            respawnTimer = respawnDelay
          }
        }
      }
      .onReady { node in
        spawnEnemy(parent: node)
      }
      .onProcess { node, delta in
        // Update pulse animation
        pulseTimer += delta

        // Handle respawn timer
        if !enemyAlive && respawnTimer > 0 {
          respawnTimer -= delta
          if respawnTimer <= 0 {
            spawnEnemy(parent: node)
          }
        }
      }
    }

    func spawnEnemy(parent: Node) {
      Engine.onNextFrame {
        let enemy = Enemy(
          type: enemyType,
          spawnPoint: position,
          patrolLeft: patrolLeft,
          patrolRight: patrolRight,
          gravity: gravity,
          state: state
        )
        let node = enemy.toNode()
        if let sceneRoot = parent.getParent() {
          sceneRoot.addChild(node: node)
        }
        enemyNode = node
        enemyAlive = true
      }
    }
  }
}
