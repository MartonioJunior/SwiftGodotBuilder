import SwiftGodot

// MARK: - SpriteSheet

/// A spritesheet defined with a dictionary of entries.
///
/// ```swift
/// let playerSheet = SpriteSheet(
///   "res://player.png",
///   tile: [16, 16],
///   columns: 8,
///   entries: [
///     "idle": 0,
///     "walk": 1...4,
///     "run": [1...4, 8],   // fps as second element
///     "hit": [[8, 9], 12]
///   ]
/// )
///
/// // Usage
/// AnimatedSprite(playerSheet.walk)
/// Sprite2D$().texture(playerSheet.idle.texture)
/// ```
@dynamicMemberLookup
public struct SpriteSheet: Sendable {
  public let path: String
  public let tileSize: Vector2
  public let columns: Int
  public let defaultFps: Double
  private let sprites: [String: Clip]

  public init(
    _ path: String,
    tile tileSize: Vector2,
    columns: Int,
    fps: Double = 4,
    entries: [String: Any]
  ) {
    self.path = path
    self.tileSize = tileSize
    self.columns = columns
    self.defaultFps = fps

    var dict: [String: Clip] = [:]
    for (name, value) in entries {
      guard let entry = SheetEntry.fromDictionary(name: name, value: value) else {
        fatalError("SpriteSheet: invalid entry for key '\(name)'")
      }
      dict[entry.name] = Clip(
        sheet: SheetRef(path: path, tileSize: tileSize, columns: columns),
        frames: entry.frames,
        fps: entry.fps ?? fps
      )
    }
    sprites = dict
  }

  public subscript(dynamicMember name: String) -> Clip {
    guard let clip = sprites[name] else {
      fatalError("Sheet: no sprite named '\(name)'")
    }
    return clip
  }

  public subscript(name: String) -> Clip? {
    sprites[name]
  }
}

// MARK: - Clip (unified sprite/animation)

/// A single sprite or animation clip from a sheet.
public struct Clip: Sendable {
  let sheet: SheetRef
  public let frames: [Int]
  public let fps: Double

  public var isAnimated: Bool { frames.count > 1 }

  /// Region for a specific frame index
  public func region(for frameIndex: Int) -> Rect2 {
    let col = Float(frameIndex % sheet.columns)
    let row = Float(frameIndex / sheet.columns)
    return Rect2(
      x: col * sheet.tileSize.x,
      y: row * sheet.tileSize.y,
      width: sheet.tileSize.x,
      height: sheet.tileSize.y
    )
  }

  /// Texture for the first frame (or only frame for single sprites)
  public var texture: AtlasTexture {
    let atlas = AtlasTexture()
    atlas.atlas = GD.load(path: sheet.path)
    atlas.region = region(for: frames[0])
    return atlas
  }

  /// Build SpriteFrames for AnimatedSprite2D
  public func makeSpriteFrames() -> SpriteFrames {
    let spriteFrames = SpriteFrames()
    spriteFrames.setAnimationSpeed(anim: "default", fps: fps)
    spriteFrames.setAnimationLoop(anim: "default", loop: true)

    for frameIndex in frames {
      let tex = AtlasTexture()
      tex.atlas = GD.load(path: sheet.path)
      tex.region = region(for: frameIndex)
      spriteFrames.addFrame(anim: "default", texture: tex)
    }

    return spriteFrames
  }
}

/// Internal reference to sheet config (for Clip to access)
struct SheetRef: Sendable {
  let path: String
  let tileSize: Vector2
  let columns: Int
}

// MARK: - Entry Parsing

struct SheetEntry: Sendable {
  let name: String
  let frames: [Int]
  let fps: Double?

  static func fromDictionary(name: String, value: Any) -> SheetEntry? {
    if let array = value as? [Any] {
      var components = array
      components.insert(name, at: 0)
      return fromComponents(components)
    }

    guard let frames = frames(from: value) else { return nil }
    return SheetEntry(name: name, frames: frames, fps: nil)
  }

  private static func fromComponents(_ components: [Any]) -> SheetEntry? {
    guard components.count == 2 || components.count == 3 else { return nil }
    guard let name = components.first as? String else { return nil }
    guard let frames = frames(from: components[1]) else { return nil }

    var fps: Double?
    if components.count == 3 {
      fps = fpsValue(from: components[2])
      if fps == nil { return nil }
    }

    return SheetEntry(name: name, frames: frames, fps: fps)
  }

  private static func frames(from spec: Any) -> [Int]? {
    switch spec {
    case let value as Int:
      return [value]
    case let range as ClosedRange<Int>:
      return Array(range)
    case let range as Swift.Range<Int>:
      return Array(range)
    case let list as [Int]:
      return list
    case let slice as ArraySlice<Int>:
      return Array(slice)
    default:
      return nil
    }
  }

  private static func fpsValue(from spec: Any) -> Double? {
    if let value = spec as? Double {
      return value
    } else if let value = spec as? Int {
      return Double(value)
    }
    return nil
  }
}

// MARK: - AnimatedSprite

/// A GView that displays a Clip using AnimatedSprite2D
///
/// ```swift
/// let sprites = SpriteSheet(
///   "res://player.png",
///   tile: [16, 16],
///   columns: 8,
///   entries: [
///     "walk": 0...4
///   ]
/// )
///
/// AnimatedSprite(sprites.walk)
/// ```
public struct AnimatedSprite: GView {
  let clip: Clip
  let spritePosition: Vector2
  let autoplay: Bool

  public init(_ clip: Clip, position: Vector2 = .zero, autoplay: Bool = true) {
    self.clip = clip
    self.spritePosition = position
    self.autoplay = autoplay
  }

  public var body: some GView {
    AnimatedSprite2D$()
      .position(spritePosition)
      .onReady { sprite in
        sprite.spriteFrames = clip.makeSpriteFrames()
        if autoplay {
          sprite.play()
        }
      }
  }
}
