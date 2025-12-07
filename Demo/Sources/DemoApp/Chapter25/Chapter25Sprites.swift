import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  enum PlayerSprite: Int, SpriteSheet {
    case walk1, walk2

    static let sheetPath = "res://hero.png"
    static let tileSize: Vector2 = [8, 8]
    static let columns = 14

    static let walk = SpriteAnimation(frames: [walk1, walk2], fps: 4)

    var visualBounds: Rect2i {
      switch self {
      case .walk1, .walk2:
        Rect2i(x: 1, y: 1, width: 6, height: 7)
      }
    }
  }

  enum ItemSprite: Int, SpriteSheet {
    case wand1, wand2, wand3, wand4, wand5
    case bow1, bow2, bow3, bow4, bow5
    case sword1, sword2, sword3, sword4, sword5
    case bow6, bow7, bow8, bow9, bow10
    case axe1, axe2, axe3, axe4, axe5
    case amethyst = 40, key, orb1, orb2, orb3
    case emerald = 50, heartOpen, coin1, coin2, coin3
    case chess1, chess2, chess3, apple, acorn
    case ruby, heartHalf, coin1side, coin2side, coin3side
    case chess4, chess5, chess6, chicken, carrot
    case diamond, heartFull, coin1back, coin2back, coin3back
    case chess7, chess8, chess9, ham, potato

    static let sheetPath = "res://items.png"
    static let tileSize: Vector2 = [8, 8]
    static let columns = 10

    static let coinSpin = SpriteAnimation(frames: [coin1, coin1side, coin1back, coin1side], fps: 4)

    var visualBounds: Rect2i {
      switch self {
      case .coin1, .coin2, .coin3, .coin1side, .coin2side, .coin3side, .coin1back, .coin2back, .coin3back:
        Rect2i(x: 2, y: 1, width: 5, height: 6)
      case .heartOpen, .heartHalf, .heartFull:
        Rect2i(x: 0, y: 0, width: 7, height: 8)
      default:
        Rect2i(x: 0, y: 0, width: 8, height: 8)
      }
    }
  }
}
