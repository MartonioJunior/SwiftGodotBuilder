import Foundation
import SwiftGodot

extension Chapter21 {
  struct LevelData {
    let id: Int
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
  }

  struct LeaderboardEntry: Codable, Equatable, Identifiable {
    let id = UUID()
    let name: String
    let time: Double
    let date: Date
    let coins: Int
    let deaths: Int

    var timeFormatted: String {
      formatTime(time)
    }

    enum CodingKeys: String, CodingKey {
      case name, time, date, coins, deaths
    }
  }

  struct LevelProgress: Codable, Equatable {
    let levelId: Int
    var completed = false
    var bestTime: Double = .infinity
    var coinsCollected: Int = 0
    var bestMedal: Medal = .none
    var leaderboard: [LeaderboardEntry] = []

    init(levelId: Int, completed: Bool = false, bestTime: Double = .infinity, coinsCollected: Int = 0) {
      self.levelId = levelId
      self.completed = completed
      self.bestTime = bestTime
      self.coinsCollected = coinsCollected
    }

    var bestTimeFormatted: String {
      bestTime == .infinity ? "--:--.--" : formatTime(bestTime)
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

  static func formatTime(_ time: Double) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
    if minutes > 0 {
      return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
    }
    return String(format: "%02d.%02d", seconds, centiseconds)
  }
}
