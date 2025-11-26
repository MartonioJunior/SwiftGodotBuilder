import SwiftGodot
import SwiftGodotBuilder

extension Chapter19 {
  static let levels: [LevelData] = [
    LevelData(
      id: 1,
      name: "Tutorial Valley",
      totalCoins: 5,
      playerSpawnPoint: [40, 100],
      goldTime: 15.0,
      silverTime: 25.0,
      bronzeTime: 40.0
    ),
    LevelData(
      id: 2,
      name: "Sky Fortress",
      totalCoins: 8,
      playerSpawnPoint: [40, 130],
      goldTime: 30.0,
      silverTime: 45.0,
      bronzeTime: 60.0
    ),
    LevelData(
      id: 3,
      name: "Final Challenge",
      totalCoins: 10,
      playerSpawnPoint: [40, 130],
      goldTime: 45.0,
      silverTime: 60.0,
      bronzeTime: 90.0
    ),
    LevelData(
      id: 4,
      name: "Boss Arena",
      totalCoins: 0,
      playerSpawnPoint: [100, 130],
      goldTime: 60.0,
      silverTime: 90.0,
      bronzeTime: 120.0
    ),
  ]

  static func getLevelData(_ id: Int) -> LevelData? {
    levels.first { $0.id == id }
  }
}
