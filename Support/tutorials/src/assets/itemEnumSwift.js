export default `import SwiftGodot
import SwiftGodotBuilder

enum Item: String, Identifiable {
  var id: String { rawValue }

  case knife = "Knife"
  case boots = "Boots"
}`;
