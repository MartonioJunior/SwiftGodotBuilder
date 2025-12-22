import Observation
import SwiftGodot

// MARK: - Persistable Protocol

/// A protocol for making classes automatically persistable to disk.
///
/// Classes conforming to `Persistable` can easily save and load their state
/// to Godot's user data directory using JSON serialization.
///
/// ## Usage
///
/// ```swift
/// @Observable
/// class GameSettings: Persistable {
///   static let PersistenceKey = "settings"
///
///   var masterVolume: Double = 0.7
///   var musicVolume: Double = 0.6
///   var fullscreen: Bool = false
///
///   init() {
///     loadPersistence()
///   }
///
///   func toDictionary() -> VariantDictionary {
///     let dict = VariantDictionary()
///     dict["masterVolume"] = Variant(masterVolume)
///     dict["musicVolume"] = Variant(musicVolume)
///     dict["fullscreen"] = Variant(fullscreen)
///     return dict
///   }
///
///   func fromDictionary(_ dict: VariantDictionary) {
///     // Using Swift type inference with .to() for cleaner variant unwrapping
///     if let value: Double = dict["masterVolume"]?.to() { masterVolume = value }
///     if let value: Double = dict["musicVolume"]?.to() { musicVolume = value }
///     if let value: Bool = dict["fullscreen"]?.to() { fullscreen = value }
///   }
/// }
/// ```
///
/// ## Auto-save with `.watchAny()`
///
/// For automatic persistence when any property changes:
///
/// ```swift
/// Node2D$ {
///   // ... your game content
/// }
/// .watchAny($settings) { _, _ in
///   settings.savePersistence()
/// }
/// ```
///
/// ## Storage Location
///
/// Files are stored in `user://[persistenceKey].json` which maps to:
/// - macOS: `~/Library/Application Support/Godot/app_userdata/[project_name]/[PersistenceKey].json`
/// - Windows: `%APPDATA%/Godot/app_userdata/[project_name]/[PersistenceKey].json`
/// - Linux: `~/.local/share/godot/app_userdata/[project_name]/[PersistenceKey].json`
public protocol Persistable: AnyObject, Observable {
  /// The key used for the persistence file (e.g., "settings" creates "user://settings.json")
  static var PersistenceKey: String { get }

  /// Convert the object's state to a VariantDictionary for serialization
  func toDictionary() -> VariantDictionary

  /// Restore the object's state from a VariantDictionary
  func fromDictionary(_ dict: VariantDictionary)
}

// MARK: - Default Implementation

public extension Persistable {
  /// The file path where this object's data is persisted
  var persistencePath: String {
    "user://\(Self.PersistenceKey).json"
  }

  /// Save the current state to disk
  func savePersistence() {
    let dict = toDictionary()
    let json = JSON.stringify(data: Variant(dict), indent: "  ")

    guard let file = FileAccess.open(path: persistencePath, flags: .write) else {
      GD.printerr(arg1: Variant("Failed to open file for writing: \(persistencePath)"))
      return
    }

    defer { file.close() }
    _ = file.storeString(json)
  }

  /// Delete the persisted data file
  func deletePersistence() {
    let dirAccess = DirAccess.open(path: "user://")
    if dirAccess?.fileExists(path: persistencePath) == true {
      _ = dirAccess?.remove(path: persistencePath)
      GD.print(arg1: Variant("Deleted persistence file: \(persistencePath)"))
    }
  }

  /// Load state from disk (if file exists)
  func loadPersistence() {
    guard let file = FileAccess.open(path: persistencePath, flags: .read) else {
      // File doesn't exist, use defaults
      return
    }

    defer { file.close() }

    let jsonString = file.getAsText()
    guard let parsed = JSON.parseString(jsonString: String(jsonString)),
          let dict = VariantDictionary(parsed)
    else {
      GD.printerr(arg1: Variant("Failed to parse JSON from: \(persistencePath)"))
      return
    }

    fromDictionary(dict)
  }

  /// Clear the persisted data (deletes the file)
  func clearPersistence() {
    if FileAccess.fileExists(path: persistencePath) {
      _ = DirAccess.removeAbsolute(path: persistencePath)
    }
  }

  /// Reset to default values and clear persisted data
  func resetPersistence() {
    clearPersistence()
    // After clearing, the next loadPersistence() will use default values
  }
}
