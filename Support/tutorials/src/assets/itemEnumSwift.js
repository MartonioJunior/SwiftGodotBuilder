export default `enum Item: String, LDExported {
  case knife = "Knife"
  case healingPlant = "Healing_Plant"
  case meat = "Meat"
  case boots = "Boots"
  case water = "Water"
  case gem = "Gem"
  case gloves = "Gloves"

  var displayName: String {
    switch self {
    case .knife: return "Knife"
    case .healingPlant: return "Healing Plant"
    case .meat: return "Meat"
    case .boots: return "Boots"
    case .water: return "Water"
    case .gem: return "Gem"
    case .gloves: return "Gloves"
    }
  }
}`
