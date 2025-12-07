import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct LevelData {
    let id: String // LDtk level identifier (e.g., "Level_0")
    let name: String
    let totalCoins: Int
    let levelWidth: Float
    let levelHeight: Float
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

      return LevelData(
        id: id,
        name: displayName,
        totalCoins: totalCoins,
        levelWidth: Float(level.pxWid),
        levelHeight: Float(level.pxHei),
        goldTime: goldTime,
        silverTime: silverTime,
        bronzeTime: bronzeTime
      )
    }
  }
}
