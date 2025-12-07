import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  @Observable
  class GameSettings: Persistable {
    static let PersistenceKey = "chapter24_settings"

    var masterVolume: Double = 0.7
    var musicVolume: Double = 0.6
    var sfxVolume: Double = 0.8
    var fullscreen = false

    // Physics (not persisted)
    var gravity: Float = 400

    init() {
      loadPersistence()
    }

    func toDictionary() -> VariantDictionary {
      let dict = VariantDictionary()
      dict["masterVolume"] = Variant(masterVolume)
      dict["musicVolume"] = Variant(musicVolume)
      dict["sfxVolume"] = Variant(sfxVolume)
      dict["fullscreen"] = Variant(fullscreen)
      return dict
    }

    func fromDictionary(_ dict: VariantDictionary) {
      if let value: Double = dict["masterVolume"]?.to() { masterVolume = value }
      if let value: Double = dict["musicVolume"]?.to() { musicVolume = value }
      if let value: Double = dict["sfxVolume"]?.to() { sfxVolume = value }
      if let value: Bool = dict["fullscreen"]?.to() { fullscreen = value }
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
    }
  }
}
