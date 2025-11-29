import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  @Observable
  class GameSettings: Persistable {
    static let PersistenceKey = "chapter20_settings"

    var masterVolume: Double = 0.7
    var musicVolume: Double = 0.6
    var sfxVolume: Double = 0.8
    var fullscreen = false

    var moveLeftKey = "a"
    var moveRightKey = "d"
    var jumpKey = "space"
    var attackKey = "x"
    var dashKey = "shift"
    var switchWeaponKey = "q"

    init() {
      loadPersistence()
    }

    func toDictionary() -> VariantDictionary {
      let dict = VariantDictionary()
      dict["masterVolume"] = Variant(masterVolume)
      dict["musicVolume"] = Variant(musicVolume)
      dict["sfxVolume"] = Variant(sfxVolume)
      dict["fullscreen"] = Variant(fullscreen)
      dict["moveLeftKey"] = Variant(moveLeftKey)
      dict["moveRightKey"] = Variant(moveRightKey)
      dict["jumpKey"] = Variant(jumpKey)
      dict["attackKey"] = Variant(attackKey)
      dict["dashKey"] = Variant(dashKey)
      dict["switchWeaponKey"] = Variant(switchWeaponKey)
      return dict
    }

    func fromDictionary(_ dict: VariantDictionary) {
      if let value: Double = dict["masterVolume"]?.to() { masterVolume = value }
      if let value: Double = dict["musicVolume"]?.to() { musicVolume = value }
      if let value: Double = dict["sfxVolume"]?.to() { sfxVolume = value }
      if let value: Bool = dict["fullscreen"]?.to() { fullscreen = value }
      if let value: String = dict["moveLeftKey"]?.to() { moveLeftKey = value }
      if let value: String = dict["moveRightKey"]?.to() { moveRightKey = value }
      if let value: String = dict["jumpKey"]?.to() { jumpKey = value }
      if let value: String = dict["attackKey"]?.to() { attackKey = value }
      if let value: String = dict["dashKey"]?.to() { dashKey = value }
      if let value: String = dict["switchWeaponKey"]?.to() { switchWeaponKey = value }
    }

    var masterVolumeDisplay: String {
      String(format: "%.0f%%", masterVolume * 100)
    }

    var musicVolumeDisplay: String {
      String(format: "%.0f%%", musicVolume * 100)
    }

    var sfxVolumeDisplay: String {
      String(format: "%.0f%%", sfxVolume * 100)
    }

    func resetToDefaults() {
      masterVolume = 0.7
      musicVolume = 0.6
      sfxVolume = 0.8
      fullscreen = false
      moveLeftKey = "a"
      moveRightKey = "d"
      jumpKey = "space"
      attackKey = "x"
      dashKey = "shift"
      switchWeaponKey = "q"
    }
  }
}
