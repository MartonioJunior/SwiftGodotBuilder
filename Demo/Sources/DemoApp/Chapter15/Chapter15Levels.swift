import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Registry

enum Chapter15 {}

extension Chapter15 {
  static let levels: [LevelData] = [
    LevelData(
      id: 1,
      name: "Tutorial Valley",
      totalCoins: 5,
      playerSpawnPoint: [40, 100]
    ),
    LevelData(
      id: 2,
      name: "Sky Fortress",
      totalCoins: 8,
      playerSpawnPoint: [40, 130]
    ),
    LevelData(
      id: 3,
      name: "Final Challenge",
      totalCoins: 10,
      playerSpawnPoint: [40, 130]
    ),
  ]

  static func getLevelData(_ id: Int) -> LevelData? {
    levels.first { $0.id == id }
  }
}
