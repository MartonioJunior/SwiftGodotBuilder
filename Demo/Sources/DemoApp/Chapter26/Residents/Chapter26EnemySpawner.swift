import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct EnemySpawner: GView {
    let definition: EnemyDefinition
    let position: Vector2
    let patrolLeft: Float
    let patrolRight: Float
    let respawnDelay: Double
    let isActive: State<Bool>

    @State var enemyAlive = false
    @State var isDestroyed = false

    @State var respawnTimer = 0.0
    @State var pulseTimer = 0.0
    @State var enemyNode: Node?

    let spawnerColor = Color(code: "#8080FF")
    let pulseColor: GState<Color>

    init(
      entity: LDEntity,
      isActive: State<Bool>
    ) {
      let enemyType: EnemyType = entity.field("enemyType")?.asEnum() ?? .patrol
      switch enemyType {
      case .patrol: definition = .patrol
      case .flyer: definition = .flyer
      }

      position = entity.positionTopLeft
      patrolLeft = entity.field("patrolLeft")?.asFloat() ?? (entity.positionCenter.x - 50)
      patrolRight = entity.field("patrolRight")?.asFloat() ?? (entity.positionCenter.x + 50)
      respawnDelay = entity.field("respawnDelay")?.asDouble() ?? 5.0
      self.isActive = isActive

      pulseColor = _pulseTimer.computed { [spawnerColor] timer in
        let alpha = 0.3 + 0.3 * sin(Float(timer * 3))
        return Color(r: spawnerColor.red, g: spawnerColor.green, b: spawnerColor.blue, a: alpha)
      }
    }

    init(
      _ definition: EnemyDefinition,
      position: Vector2,
      patrolLeft: Float,
      patrolRight: Float,
      respawnDelay: Double = 5.0,
      isActive: State<Bool>
    ) {
      self.definition = definition
      self.position = position
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight
      self.respawnDelay = respawnDelay
      self.isActive = isActive

      pulseColor = _pulseTimer.computed { [spawnerColor] timer in
        let alpha = 0.3 + 0.3 * sin(Float(timer * 3))
        return Color(r: spawnerColor.red, g: spawnerColor.green, b: spawnerColor.blue, a: alpha)
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
      .onEvent(GameEvent.self) { _, event in
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
      Engine.onNextFrame { [weak parent] in
        guard let parent, parent.isInsideTree() else { return }
        let enemy = EnemyView(
          definition: definition,
          spawnPoint: position,
          patrolLeft: patrolLeft,
          patrolRight: patrolRight,
          isActive: isActive
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
