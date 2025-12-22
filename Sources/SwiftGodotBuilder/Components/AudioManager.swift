import Foundation
import SwiftGodot

/// Audio manager that syncs volume settings with Godot's AudioServer.
/// Pass your own SFX player nodes as children.
public struct AudioManager<Content: GView>: GView {
  let settings: UserSettings
  let content: Content

  public init(
    settings: UserSettings,
    @GViewBuilder content: () -> Content
  ) {
    self.settings = settings
    self.content = content()
  }

  public var body: some GView {
    Node2D$ {
      content
    }
    .onReady { _ in
      applyVolumeSettings()
    }
  }

  func applyVolumeSettings() {
    let masterDb = linearToDb(settings.masterVolume * settings.sfxVolume)
    AudioServer.setBusVolumeDb(busIdx: 0, volumeDb: Double(masterDb))
  }

  func linearToDb(_ linear: Double) -> Float {
    if linear <= 0 { return -80.0 }
    return Float(20.0 * log10(linear))
  }
}
