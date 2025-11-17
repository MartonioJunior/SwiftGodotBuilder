export default `import SwiftGodot
import SwiftGodotBuilder

enum GameEvent: EmittableEvent {
  case itemCollected(Item)
  case enemyHit(Area2D)
}`;
