import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  enum GameState {
    case splash
    case welcome
    case levelSelect
    case playing
    case paused
    case settings
    case levelComplete
    case gameOver
    case leaderboard
    case dialog
    case death
    case credits
  }
}

// MARK: - State Groups

extension Chapter26.GameState {
  /// States where the game content and HUD should be visible
  static let inGame: Set<Self> = [
    .playing, .paused, .levelComplete, .death, .dialog, .gameOver,
  ]

  /// States where gameplay is active (not paused/dead/etc)
  static let active: Set<Self> = [.playing, .dialog]

  /// Menu states (non-gameplay)
  static let menu: Set<Self> = [
    .splash, .welcome, .levelSelect, .credits, .leaderboard, .settings,
  ]

  var isInGame: Bool { Self.inGame.contains(self) }
  var isActive: Bool { Self.active.contains(self) }
  var isMenu: Bool { Self.menu.contains(self) }
}
