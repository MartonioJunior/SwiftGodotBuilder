import SwiftGodot

/// Protocol for defining sprites within a spritesheet.
/// Conform your enum to this protocol and provide the sheet configuration.
///
/// Example:
/// ```swift
/// enum ItemSprite: Int, SpriteSheet {
///   case heart = 0
///   case key = 1
///   // tile 2 is blank
///   case coin = 3
///   case sword = 4
///
///   static let sheetPath = "res://items.png"
///   static let tileSize: Vector2 = [16, 16]
///   static let columns = 4
///
///   // Optional: specify visual bounds for sprites smaller than tile size
///   var visualBounds: Rect2i {
///     switch self {
///     case .coin: Rect2i(x: 2, y: 1, width: 4, height: 6)
///     default: Rect2i(x: 0, y: 0, width: 16, height: 16)
///     }
///   }
/// }
///
/// // Usage
/// Sprite2D$().texture(ItemSprite.heart.texture)
/// ```
public protocol SpriteSheet: RawRepresentable, Sendable where RawValue == Int {
  /// Path to the spritesheet texture resource
  static var sheetPath: String { get }

  /// Size of each tile in pixels
  static var tileSize: Vector2 { get }

  /// Number of columns in the sheet (tiles per row)
  static var columns: Int { get }

  /// Visual bounds within the tile (defaults to full tile).
  /// Override this to specify the actual pixel bounds for sprites smaller than the tile size.
  var visualBounds: Rect2i { get }
}

public extension SpriteSheet {
  /// Default visual bounds - the full tile
  var visualBounds: Rect2i {
    Rect2i(x: 0, y: 0, width: Int32(Self.tileSize.x), height: Int32(Self.tileSize.y))
  }

  /// The visual size of the sprite (from visualBounds) as Vector2i
  var visualSize: Vector2i {
    visualBounds.size
  }

  /// The visual size as Vector2, suitable for use with .minSize()
  var minSize: Vector2 {
    let size = visualBounds.size
    return [Float(size.x), Float(size.y)]
  }

  /// Offset to align the visual center with the tile center.
  /// Apply this offset to position sprites correctly when visual bounds differ from tile size.
  var visualOffset: Vector2 {
    let b = visualBounds
    let tileCenter = Self.tileSize / 2
    let visualCenterX = Float(b.position.x) + Float(b.size.x) / 2
    let visualCenterY = Float(b.position.y) + Float(b.size.y) / 2
    return Vector2(x: tileCenter.x - visualCenterX, y: tileCenter.y - visualCenterY)
  }

  /// The region within the spritesheet for this sprite
  var region: Rect2 {
    let col = Float(rawValue % Self.columns)
    let row = Float(rawValue / Self.columns)
    return Rect2(
      x: col * Self.tileSize.x,
      y: row * Self.tileSize.y,
      width: Self.tileSize.x,
      height: Self.tileSize.y
    )
  }

  /// Creates an AtlasTexture for this sprite
  var texture: AtlasTexture {
    let atlas = AtlasTexture()
    atlas.atlas = GD.load(path: Self.sheetPath)
    atlas.region = region
    return atlas
  }
}

// MARK: - Sprite Animation

/// A simple looping animation defined by a sequence of sprites
///
/// Example:
/// ```swift
/// extension ItemSprite {
///   static let coinSpin = SpriteAnimation(frames: [.coin1, .coin1side, .coin1back], fps: 4)
/// }
///
/// // Usage
/// AnimatedSpriteSheet$(ItemSprite.coinSpin)
/// ```
public struct SpriteAnimation<S: SpriteSheet>: Sendable {
  public let frames: [S]
  public let fps: Double

  public init(frames: [S], fps: Double = 4) {
    self.frames = frames
    self.fps = fps
  }

  /// Build a SpriteFrames resource with a "default" animation
  public func makeSpriteFrames() -> SpriteFrames {
    let spriteFrames = SpriteFrames()
    spriteFrames.setAnimationSpeed(anim: "default", fps: fps)
    spriteFrames.setAnimationLoop(anim: "default", loop: true)

    for frame in frames {
      spriteFrames.addFrame(anim: "default", texture: frame.texture)
    }

    return spriteFrames
  }
}

/// A GView that displays an animated spritesheet sequence using Godot's AnimatedSprite2D
public struct AnimatedSpriteSheet<S: SpriteSheet>: GView {
  let animation: SpriteAnimation<S>
  let spritePosition: Vector2
  let autoplay: Bool

  public init(_ animation: SpriteAnimation<S>, position: Vector2 = .zero, autoplay: Bool = true) {
    self.animation = animation
    spritePosition = position
    self.autoplay = autoplay
  }

  public var body: some GView {
    AnimatedSprite2D$()
      .position(spritePosition)
      .onReady { sprite in
        sprite.spriteFrames = animation.makeSpriteFrames()
        if autoplay {
          sprite.play()
        }
      }
  }
}
