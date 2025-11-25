import SwiftGodot

extension Chapter18 {
  struct LevelData {
    let id: Int
    let name: String
    let totalCoins: Int
    let playerSpawnPoint: Vector2
  }

  struct LevelProgress: Codable, Equatable {
    let levelId: Int
    var completed = false
    var bestTime: Double = .infinity
    var coinsCollected: Int = 0

    init(levelId: Int, completed: Bool = false, bestTime: Double = .infinity, coinsCollected: Int = 0) {
      self.levelId = levelId
      self.completed = completed
      self.bestTime = bestTime
      self.coinsCollected = coinsCollected
    }

    mutating func update(time: Double, coins: Int) {
      completed = true
      if time < bestTime {
        bestTime = time
      }
      coinsCollected = max(coinsCollected, coins)
    }
  }
}
