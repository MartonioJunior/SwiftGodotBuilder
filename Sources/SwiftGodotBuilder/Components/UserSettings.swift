import Foundation
import Observation
import SwiftGodot

/// Persistable user settings for audio volumes and display options
@Observable
public class UserSettings: Persistable {
  public static let PersistenceKey = "user_settings"

  public var masterVolume: Double = 0.7
  public var musicVolume: Double = 0.6
  public var sfxVolume: Double = 0.8
  public var fullscreen = false

  public init() {
    loadPersistence()
  }

  public func toDictionary() -> VariantDictionary {
    let dict = VariantDictionary()
    dict["masterVolume"] = Variant(masterVolume)
    dict["musicVolume"] = Variant(musicVolume)
    dict["sfxVolume"] = Variant(sfxVolume)
    dict["fullscreen"] = Variant(fullscreen)
    return dict
  }

  public func fromDictionary(_ dict: VariantDictionary) {
    if let value: Double = dict["masterVolume"]?.to() { masterVolume = value }
    if let value: Double = dict["musicVolume"]?.to() { musicVolume = value }
    if let value: Double = dict["sfxVolume"]?.to() { sfxVolume = value }
    if let value: Bool = dict["fullscreen"]?.to() { fullscreen = value }
  }

  public var masterVolumeDisplay: String {
    String(format: "%.0f%%", masterVolume * 100)
  }

  public var musicVolumeDisplay: String {
    String(format: "%.0f%%", musicVolume * 100)
  }

  public var sfxVolumeDisplay: String {
    String(format: "%.0f%%", sfxVolume * 100)
  }

  public func resetToDefaults() {
    masterVolume = 0.7
    musicVolume = 0.6
    sfxVolume = 0.8
    fullscreen = false
  }
}
