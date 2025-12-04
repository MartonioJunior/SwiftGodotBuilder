import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  /// Item types that can be collected or dropped
  enum Item: String, LDExported {
    case coin = "Coin"
    case key = "Key"
    case ammo = "Ammo"
    case health = "Health"
  }

  /// Definition for a collectible item
  struct CollectibleDefinition {
    let size: Float
    let color: Color
    let shape: PackedVector2Array
    let collectEvent: (Vector2) -> GameEvent
  }
}

// MARK: - Collectible Colors & Shapes

extension Chapter24.CollectibleDefinition {
  // Shapes
  private static func octagonShape(radius: Float) -> PackedVector2Array {
    var points: [Vector2] = []
    for i in 0 ..< 8 {
      let angle = Float(i) * .pi * 2 / 8
      points.append([cos(angle) * radius, sin(angle) * radius])
    }
    return PackedVector2Array(points)
  }

  private static func heartShape(size: Float) -> PackedVector2Array {
    let s = size / 8
    return PackedVector2Array([
      [0, s * 2],
      [-s * 2, -s],
      [-s, -s * 2],
      [0, -s],
      [s, -s * 2],
      [s * 2, -s],
    ])
  }

  // Definitions
  static var coin: Chapter24.CollectibleDefinition {
    Chapter24.CollectibleDefinition(
      size: 8,
      color: Color(code: "#FF991A"),
      shape: octagonShape(radius: 2),
      collectEvent: { Chapter24.GameEvent.coinCollected(position: $0) }
    )
  }

  static var key: Chapter24.CollectibleDefinition {
    Chapter24.CollectibleDefinition(
      size: 8,
      color: Color(code: "#FFE633"),
      shape: PackedVector2Array([[-2, -4], [2, -4], [2, 4], [-2, 4]]),
      collectEvent: { Chapter24.GameEvent.keyCollected(position: $0) }
    )
  }

  static var ammo: Chapter24.CollectibleDefinition {
    Chapter24.CollectibleDefinition(
      size: 8,
      color: Color(code: "#4DCCFF"),
      shape: PackedVector2Array([[4, 0], [0, -3], [-2, -2], [-2, 2], [0, 3]]),
      collectEvent: { Chapter24.GameEvent.ammoCollected(position: $0) }
    )
  }

  static var health: Chapter24.CollectibleDefinition {
    Chapter24.CollectibleDefinition(
      size: 8,
      color: Color(code: "#FF4D80"),
      shape: heartShape(size: 8),
      collectEvent: { Chapter24.GameEvent.healthCollected(position: $0) }
    )
  }
}
