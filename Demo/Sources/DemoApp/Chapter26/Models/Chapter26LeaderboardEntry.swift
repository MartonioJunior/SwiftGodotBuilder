import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct LeaderboardEntry: Codable, Equatable, Identifiable {
    let id = UUID()
    let name: String
    let time: Double
    let date: Date
    let coins: Int
    let deaths: Int

    var timeFormatted: String {
      time.asTimeString
    }

    enum CodingKeys: String, CodingKey {
      case name, time, date, coins, deaths
    }
  }
}
