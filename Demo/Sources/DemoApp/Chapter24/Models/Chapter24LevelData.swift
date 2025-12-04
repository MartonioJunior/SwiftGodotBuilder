import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct LevelData {
    let id: String // LDtk level identifier (e.g., "Level_0")
    let name: String
    let totalCoins: Int
    let playerSpawnPoint: Vector2
    let levelWidth: Float
    let goldTime: Double
    let silverTime: Double
    let bronzeTime: Double

    func medal(for time: Double) -> Medal {
      if time <= goldTime { return .gold }
      if time <= silverTime { return .silver }
      if time <= bronzeTime { return .bronze }
      return .none
    }

    static func data(for id: String?, in project: LDProject) -> LevelData? {
      guard let id, let level = project.level(id) else { return nil }

      let displayName = level.field("displayName")?.asString() ?? level.identifier
      let totalCoins = level.field("totalCoins")?.asInt() ?? 5
      let goldTime = level.field("goldTime")?.asDouble() ?? 30.0
      let silverTime = level.field("silverTime")?.asDouble() ?? 45.0
      let bronzeTime = level.field("bronzeTime")?.asDouble() ?? 60.0

      var playerSpawnPoint: Vector2 = [40, 100]
      for entityLayer in level.entityLayers {
        if let playerSpawn = entityLayer.entityInstances.first(where: { $0.identifier == "PlayerSpawn" }) {
          playerSpawnPoint = playerSpawn.positionTopLeft
          break
        }
      }

      return LevelData(
        id: id,
        name: displayName,
        totalCoins: totalCoins,
        playerSpawnPoint: playerSpawnPoint,
        levelWidth: Float(level.pxWid),
        goldTime: goldTime,
        silverTime: silverTime,
        bronzeTime: bronzeTime
      )
    }
  }
}
