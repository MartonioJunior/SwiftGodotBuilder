import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Typealias for the game's scene router
  typealias GameRouter = SceneRouter<GameState>

  /// Project/level state: level data, checkpoints, spawn points.
  @Observable
  class ProjectState {
    let project: LDProject

    init(project: LDProject) {
      self.project = project
    }

    // World physics
    var gravity: Float = 400

    // Spawn & checkpoints
    var spawnPosition: Vector2 = .zero
    var activatedCheckpointIds: Set<Int> = []

    // Level state
    var currentLevelId = ""
    var currentLevelIid = ""
    var currentLevelData: LevelData?
    var playTime: Double = 0

    // Leaderboard
    var leaderboardLevelId: String?

    // MARK: - Computed Properties

    var playTimeDisplay: String { playTime.asTimeString }

    var currentMedal: Medal {
      currentLevelData?.medal(for: playTime) ?? .none
    }

    var levelNameDisplay: String {
      currentLevelData?.name ?? "Level \(currentLevelId.isEmpty ? "?" : currentLevelId)"
    }

    var nextLevelId: String {
      let levelIds = project.allLevels.map { $0.identifier }
      guard !currentLevelId.isEmpty,
            let currentIndex = levelIds.firstIndex(of: currentLevelId),
            currentIndex + 1 < levelIds.count else { return "" }
      return levelIds[currentIndex + 1]
    }

    // MARK: - Level Methods

    func prepareLevel(_ levelId: String) {
      currentLevelId = levelId
      currentLevelIid = project.level(levelId)?.iid ?? ""
      currentLevelData = LevelData.data(for: levelId, in: project)
      reset()
    }

    func reset() {
      playTime = 0
      activatedCheckpointIds = []
      spawnPosition = .zero

      GameEvent.gameReset.emit()
    }

    func respawnAfterDeath() {
      GameEvent.gameReset.emit()
    }

    func handleGoalReached() -> Bool {
      return true
    }

    func handleCheckpointActivated(id: Int, position: Vector2) {
      guard !activatedCheckpointIds.contains(id) else { return }
      activatedCheckpointIds.insert(id)
      spawnPosition = position
    }

    func setLeaderboardLevel(_ levelId: String?) {
      leaderboardLevelId = levelId
    }
  }
}
