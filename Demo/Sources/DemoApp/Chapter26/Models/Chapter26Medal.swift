import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  enum Medal: String, Codable {
    case gold
    case silver
    case bronze
    case none

    var color: String {
      switch self {
      case .gold: "#FFD700"
      case .silver: "#C0C0C0"
      case .bronze: "#CD7F32"
      case .none: "#808080"
      }
    }

    var name: String {
      switch self {
      case .gold: "Gold"
      case .silver: "Silver"
      case .bronze: "Bronze"
      case .none: "No Medal"
      }
    }

    var animation: String? {
      switch self {
      case .gold: "orbGold"
      case .silver: "orbSilver"
      case .bronze: "orbBronze"
      case .none: nil
      }
    }
  }
}
