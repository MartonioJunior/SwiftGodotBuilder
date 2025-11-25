import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  @Observable
  class GameProgress: Persistable {
    static let PersistenceKey = "chapter18_progress"

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

    func updateProgress(for levelId: Int, time: Double, coins: Int) {
      if let idx = index(for: levelId) {
        var progress = levels[idx]
        progress.update(time: time, coins: coins)
        levels[idx] = progress
      } else {
        var progress = LevelProgress(levelId: levelId)
        progress.update(time: time, coins: coins)
        levels.append(progress)
      }
      GD.print(arg1: Variant("Saving progress for level \(levelId): completed=\(getProgress(for: levelId).completed)"))
      savePersistence()
      GD.print(arg1: Variant("Progress saved to: \(persistencePath)"))
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
