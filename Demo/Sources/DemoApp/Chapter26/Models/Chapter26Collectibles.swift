import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// Item types that can be collected or dropped
  enum Item: String, LDExported {
    case coin = "Coin"
    case key = "Key"
    case ammo = "Ammo"
    case health = "Health"

    /// Animation tag name from Items.aseprite
    var animation: String {
      switch self {
      case .coin: "coinGold"
      case .key: "key"
      case .ammo: "emerald"
      case .health: "heart"
      }
    }
  }
}
