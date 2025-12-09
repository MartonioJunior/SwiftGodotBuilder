import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct LevelProgress: Codable, Equatable {
    let levelId: String // LDtk level identifier
    var completed = false
    var bestTime: Double = .infinity
    var coinsCollected: Int = 0
    var bestMedal: Medal = .none
    var leaderboard: [LeaderboardEntry] = []

    init(levelId: String, completed: Bool = false, bestTime: Double = .infinity, coinsCollected: Int = 0) {
      self.levelId = levelId
      self.completed = completed
      self.bestTime = bestTime
      self.coinsCollected = coinsCollected
    }

    var bestTimeFormatted: String {
      bestTime == .infinity ? "--:--.--" : bestTime.asTimeString
    }

    mutating func update(time: Double, coins: Int, deaths: Int = 0, medal: Medal) {
      completed = true
      let isNewBest = time < bestTime
      if isNewBest {
        bestTime = time
      }
      coinsCollected = max(coinsCollected, coins)

      if medal.rawValue > bestMedal.rawValue || (medal != .none && bestMedal == .none) {
        bestMedal = medal
      }

      // Add to leaderboard
      let entry = LeaderboardEntry(
        name: "Player",
        time: time,
        date: Date(),
        coins: coins,
        deaths: deaths
      )
      leaderboard.append(entry)
      leaderboard.sort { $0.time < $1.time }
      // Keep top 10
      if leaderboard.count > 10 {
        leaderboard = Array(leaderboard.prefix(10))
      }
    }
  }
}
