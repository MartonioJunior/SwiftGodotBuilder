import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  @Observable
  class GameProgress: Persistable {
    static let PersistenceKey = "chapter20_progress"

    var levels: [LevelProgress] = []
    var currentLevelIndex: Int = 0

    init() {
      loadPersistence()
    }

    func toDictionary() -> VariantDictionary {
      let dict = VariantDictionary()

      let levelsArray = VariantArray()
      for progress in levels {
        let levelDict = VariantDictionary()
        levelDict["levelId"] = Variant(progress.levelId)
        levelDict["completed"] = Variant(progress.completed)
        levelDict["bestTime"] = Variant(progress.bestTime)
        levelDict["coinsCollected"] = Variant(progress.coinsCollected)
        levelDict["bestMedal"] = Variant(progress.bestMedal.rawValue)

        // Serialize leaderboard
        let leaderboardArray = VariantArray()
        for entry in progress.leaderboard {
          let entryDict = VariantDictionary()
          entryDict["name"] = Variant(entry.name)
          entryDict["time"] = Variant(entry.time)
          entryDict["date"] = Variant(entry.date.timeIntervalSince1970)
          entryDict["coins"] = Variant(entry.coins)
          entryDict["deaths"] = Variant(entry.deaths)
          leaderboardArray.append(Variant(entryDict))
        }
        levelDict["leaderboard"] = Variant(leaderboardArray)

        levelsArray.append(Variant(levelDict))
      }
      dict["levels"] = Variant(levelsArray)
      dict["currentLevelIndex"] = Variant(currentLevelIndex)

      return dict
    }

    func fromDictionary(_ dict: VariantDictionary) {
      if let levelsVariant = dict["levels"],
         let levelsArray = VariantArray(levelsVariant)
      {
        levels.removeAll()
        for i in 0 ..< levelsArray.size() {
          guard let levelDict = VariantDictionary(levelsArray[Int(i)]) else { continue }

          let levelId: Int = levelDict["levelId"]?.to() ?? (Int(i) + 1)
          var progress = LevelProgress(levelId: levelId)
          if let completed: Bool = levelDict["completed"]?.to() {
            progress.completed = completed
          }
          if let bestTime: Double = levelDict["bestTime"]?.to() {
            progress.bestTime = bestTime
          }
          if let coins: Int64 = levelDict["coinsCollected"]?.to() {
            progress.coinsCollected = Int(coins)
          }
          if let medalRaw: String = levelDict["bestMedal"]?.to(),
             let medal = Medal(rawValue: medalRaw)
          {
            progress.bestMedal = medal
          }

          // Deserialize leaderboard
          if let leaderboardVariant = levelDict["leaderboard"],
             let leaderboardArray = VariantArray(leaderboardVariant)
          {
            for j in 0 ..< leaderboardArray.size() {
              guard let entryDict = VariantDictionary(leaderboardArray[Int(j)]) else { continue }
              let name: String = entryDict["name"]?.to() ?? "Player"
              let time: Double = entryDict["time"]?.to() ?? 0
              let dateInterval: Double = entryDict["date"]?.to() ?? 0
              let coins: Int = Int(entryDict["coins"]?.to() as Int64? ?? 0)
              let deaths: Int = Int(entryDict["deaths"]?.to() as Int64? ?? 0)
              let entry = LeaderboardEntry(
                name: name,
                time: time,
                date: Date(timeIntervalSince1970: dateInterval),
                coins: coins,
                deaths: deaths
              )
              progress.leaderboard.append(entry)
            }
          }

          levels.append(progress)
        }
      }

      if let index: Int64 = dict["currentLevelIndex"]?.to() {
        currentLevelIndex = Int(index)
      }
    }

    private func index(for levelId: Int) -> Int? {
      levels.firstIndex { $0.levelId == levelId }
    }

    func getProgress(for levelId: Int) -> LevelProgress {
      if let idx = index(for: levelId) {
        return levels[idx]
      }
      return LevelProgress(levelId: levelId)
    }

    func updateProgress(for levelId: Int, time: Double, coins: Int, deaths: Int) {
      let levelData = Chapter20.getLevelData(levelId)
      let medal = levelData?.medal(for: time) ?? .none

      if let idx = index(for: levelId) {
        var progress = levels[idx]
        progress.update(time: time, coins: coins, deaths: deaths, medal: medal)
        levels[idx] = progress
      } else {
        var progress = LevelProgress(levelId: levelId)
        progress.update(time: time, coins: coins, deaths: deaths, medal: medal)
        levels.append(progress)
      }
      savePersistence()
    }

    func getLeaderboard(for levelId: Int) -> [LeaderboardEntry] {
      getProgress(for: levelId).leaderboard
    }

    func isLevelUnlocked(_ levelId: Int) -> Bool {
      if levelId == 1 { return true }
      let previousProgress = getProgress(for: levelId - 1)
      return previousProgress.completed
    }

    func clearProgress() {
      levels.removeAll()
      currentLevelIndex = 0
      deletePersistence()
    }
  }
}
