export default `import SwiftGodot
import SwiftGodotBuilder

struct EnemyView: GView {
  let startPos: Vector2
  let patrolDistance: Float = 75.0
  let speed: Float = 50.0

  @State var position: Vector2 = .zero
  @State var movingRight = true

  init(startPos: Vector2) {
    self.startPos = startPos
  }

  var body: some GView {
    Area2D$ {
      // Visual representation
      ColorBox$()
        .color(.red)
        .size([32, 32])
        .position([-16, -16])

      // Collision shape
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 32, h: 32))
    }
    .position($position)
    .onReady { _ in
      position = startPos
    }
    .onProcess { _, delta in
      updatePatrol(delta)
    }
  }

  func updatePatrol(_ delta: Double) {
    let minX = startPos.x - patrolDistance
    let maxX = startPos.x + patrolDistance

    // Move in current direction
    if movingRight {
      position.x += speed * Float(delta)
      if position.x >= maxX {
        movingRight = false
      }
    } else {
      position.x -= speed * Float(delta)
      if position.x <= minX {
        movingRight = true
      }
    }
  }
}`;
