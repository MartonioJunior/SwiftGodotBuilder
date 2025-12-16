import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct EnemySpawner: GView {
    let definition: EnemyDefinition
    let position: Vector2
    let patrolLeft: Float
    let patrolRight: Float
    let respawnDelay: Double
    let worldGravity: Float

    private final class SpawnerState {
      var isDestroyed = false
      var respawnTimer = 0.0
      var pulseTimer = 0.0
      var enemyNode: Node?
      var colorBox: ColorBox?
      var enemyAlive = false
    }

    private let ss = SpawnerState()

    let spawnerColor = Color(code: "#8080FF")

    init(
      entity: LDEntity,
      worldGravity: Float
    ) {
      self.worldGravity = worldGravity
      let enemyType: EnemyType = entity.field("enemyType")?.asEnum() ?? .patrol
      switch enemyType {
      case .patrol: definition = .patrol
      case .flyer: definition = .flyer
      }

      position = entity.positionTopLeft
      patrolLeft = entity.field("patrolLeft")?.asFloat() ?? (entity.positionCenter.x - 50)
      patrolRight = entity.field("patrolRight")?.asFloat() ?? (entity.positionCenter.x + 50)
      respawnDelay = entity.field("respawnDelay")?.asDouble() ?? 5.0
    }

    init(
      _ definition: EnemyDefinition,
      position: Vector2,
      patrolLeft: Float,
      patrolRight: Float,
      respawnDelay: Double = 5.0,
      worldGravity: Float
    ) {
      self.definition = definition
      self.position = position
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight
      self.respawnDelay = respawnDelay
      self.worldGravity = worldGravity
    }

    var body: some GView {
      Node2D$ {
        // Visual indicator - pulsing square
        ColorBox$()
          .size([8, 8])
          .color(spawnerColor)
          .onReady { [ss] node in ss.colorBox = node }
      }
      .position(position)
      .onEvent(GameEvent.self) { [ss, position, respawnDelay] _, event in
        if case let .enemyKilled(pos) = event {
          // Check if this is our enemy (approximate position match)
          if abs(pos.x - position.x) < 50 && abs(pos.y - position.y) < 50 {
            ss.enemyNode = nil
            ss.enemyAlive = false
            ss.respawnTimer = respawnDelay
          }
        }
      }
      .onReady { node in
        spawnEnemy(parent: node)
      }
      .onProcess { [ss, spawnerColor] node, delta in
        // Update pulse animation and visibility
        ss.colorBox?.visible = !ss.enemyAlive
        ss.pulseTimer += delta
        let alpha = 0.3 + 0.3 * sin(Float(ss.pulseTimer * 3))
        ss.colorBox?.color = Color(r: spawnerColor.red, g: spawnerColor.green, b: spawnerColor.blue, a: alpha)

        // Handle respawn timer
        if !ss.enemyAlive && ss.respawnTimer > 0 {
          ss.respawnTimer -= delta
          if ss.respawnTimer <= 0 {
            spawnEnemy(parent: node)
          }
        }
      }
    }

    private func spawnEnemy(parent: Node) {
      Engine.onNextFrame { [weak parent, ss, definition, position, patrolLeft, patrolRight, worldGravity] in
        guard let parent, parent.isInsideTree() else { return }
        let enemy = EnemyActorView(
          definition: definition,
          spawnPoint: position,
          patrolLeft: patrolLeft,
          patrolRight: patrolRight,
          worldGravity: worldGravity
        )
        let node = enemy.toNode()
        if let sceneRoot = parent.getParent() {
          sceneRoot.addChild(node: node)
        }
        ss.enemyNode = node
        ss.enemyAlive = true
      }
    }
  }
}
