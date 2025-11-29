import SwiftGodot

// MARK: - Tweenable Property Protocol

/// A protocol for type-safe tween property references.
///
/// Properties conforming to this protocol can be used with the reactive
/// `tweenToggle()` modifier for state-driven animations.
///
/// ## Usage
/// ```swift
/// // Use with reactive modifiers
/// Button$()
///   .tweenToggle($isHovered, TweenProp.Scale.self,
///                whenTrue: [1.1, 1.1], whenFalse: [1.0, 1.0],
///                duration: 0.1)
///
/// // Custom properties can be defined:
/// extension TweenProp {
///   struct CustomFloat: TweenableProperty {
///     typealias Value = Float
///     static let propertyName = "custom_property"
///   }
/// }
/// ```
public protocol TweenableProperty {
  associatedtype Value
  static var propertyName: String { get }
}

// MARK: - Common Tweenable Properties

/// Namespace for built-in tweenable properties.
///
/// Access these as static members: `.scale`, `.position`, `.rotation`, etc.
public enum TweenProp {
  /// Node2D/Control scale property (Vector2)
  public struct Scale: TweenableProperty {
    public typealias Value = Vector2
    public static let propertyName = "scale"
  }

  /// Node2D/Control position property (Vector2)
  public struct Position: TweenableProperty {
    public typealias Value = Vector2
    public static let propertyName = "position"
  }

  /// Global position property (Vector2)
  public struct GlobalPosition: TweenableProperty {
    public typealias Value = Vector2
    public static let propertyName = "global_position"
  }

  /// Node2D rotation property in radians (Float)
  public struct Rotation: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "rotation"
  }

  /// Node2D rotation in degrees (Float)
  public struct RotationDegrees: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "rotation_degrees"
  }

  /// CanvasItem modulate color (Color)
  public struct Modulate: TweenableProperty {
    public typealias Value = Color
    public static let propertyName = "modulate"
  }

  /// CanvasItem modulate alpha component (Float, 0-1)
  public struct ModulateA: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "modulate:a"
  }

  /// CanvasItem self-modulate color (Color)
  public struct SelfModulate: TweenableProperty {
    public typealias Value = Color
    public static let propertyName = "self_modulate"
  }

  /// CanvasItem self-modulate alpha (Float, 0-1)
  public struct SelfModulateA: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "self_modulate:a"
  }

  /// Control size property (Vector2)
  public struct Size: TweenableProperty {
    public typealias Value = Vector2
    public static let propertyName = "size"
  }

  /// Control minimum size property (Vector2)
  public struct MinSize: TweenableProperty {
    public typealias Value = Vector2
    public static let propertyName = "custom_minimum_size"
  }

  /// Control pivot offset (Vector2)
  public struct PivotOffset: TweenableProperty {
    public typealias Value = Vector2
    public static let propertyName = "pivot_offset"
  }

  /// X position component (Float)
  public struct PositionX: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "position:x"
  }

  /// Y position component (Float)
  public struct PositionY: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "position:y"
  }

  /// X scale component (Float)
  public struct ScaleX: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "scale:x"
  }

  /// Y scale component (Float)
  public struct ScaleY: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "scale:y"
  }

  /// Node2D skew property (Float)
  public struct Skew: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "skew"
  }

  /// AudioStreamPlayer volume_db property (Float)
  public struct VolumeDb: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "volume_db"
  }

  /// AudioStreamPlayer pitch_scale property (Float)
  public struct PitchScale: TweenableProperty {
    public typealias Value = Float
    public static let propertyName = "pitch_scale"
  }
}

// MARK: - Shorthand Access

/// Shorthand access to common tweenable properties.
///
/// These extensions allow cleaner syntax for reactive modifiers:
/// ```swift
/// .tweenToggle($isHovered, .scale, whenTrue: [1.1, 1.1], whenFalse: [1.0, 1.0], duration: 0.1)
/// // instead of:
/// .tweenToggle($isHovered, TweenProp.Scale.self, whenTrue: [1.1, 1.1], whenFalse: [1.0, 1.0], duration: 0.1)
/// ```
public extension TweenableProperty where Self == TweenProp.Scale {
  static var scale: TweenProp.Scale.Type { TweenProp.Scale.self }
}

public extension TweenableProperty where Self == TweenProp.Position {
  static var position: TweenProp.Position.Type { TweenProp.Position.self }
}

public extension TweenableProperty where Self == TweenProp.GlobalPosition {
  static var globalPosition: TweenProp.GlobalPosition.Type { TweenProp.GlobalPosition.self }
}

public extension TweenableProperty where Self == TweenProp.Rotation {
  static var rotation: TweenProp.Rotation.Type { TweenProp.Rotation.self }
}

public extension TweenableProperty where Self == TweenProp.RotationDegrees {
  static var rotationDegrees: TweenProp.RotationDegrees.Type { TweenProp.RotationDegrees.self }
}

public extension TweenableProperty where Self == TweenProp.Modulate {
  static var modulate: TweenProp.Modulate.Type { TweenProp.Modulate.self }
}

public extension TweenableProperty where Self == TweenProp.ModulateA {
  static var modulateA: TweenProp.ModulateA.Type { TweenProp.ModulateA.self }
}

public extension TweenableProperty where Self == TweenProp.SelfModulate {
  static var selfModulate: TweenProp.SelfModulate.Type { TweenProp.SelfModulate.self }
}

public extension TweenableProperty where Self == TweenProp.SelfModulateA {
  static var selfModulateA: TweenProp.SelfModulateA.Type { TweenProp.SelfModulateA.self }
}

public extension TweenableProperty where Self == TweenProp.Size {
  static var size: TweenProp.Size.Type { TweenProp.Size.self }
}

public extension TweenableProperty where Self == TweenProp.MinSize {
  static var minSize: TweenProp.MinSize.Type { TweenProp.MinSize.self }
}

public extension TweenableProperty where Self == TweenProp.PivotOffset {
  static var pivotOffset: TweenProp.PivotOffset.Type { TweenProp.PivotOffset.self }
}

public extension TweenableProperty where Self == TweenProp.PositionX {
  static var positionX: TweenProp.PositionX.Type { TweenProp.PositionX.self }
}

public extension TweenableProperty where Self == TweenProp.PositionY {
  static var positionY: TweenProp.PositionY.Type { TweenProp.PositionY.self }
}

public extension TweenableProperty where Self == TweenProp.ScaleX {
  static var scaleX: TweenProp.ScaleX.Type { TweenProp.ScaleX.self }
}

public extension TweenableProperty where Self == TweenProp.ScaleY {
  static var scaleY: TweenProp.ScaleY.Type { TweenProp.ScaleY.self }
}

public extension TweenableProperty where Self == TweenProp.Skew {
  static var skew: TweenProp.Skew.Type { TweenProp.Skew.self }
}

public extension TweenableProperty where Self == TweenProp.VolumeDb {
  static var volumeDb: TweenProp.VolumeDb.Type { TweenProp.VolumeDb.self }
}

public extension TweenableProperty where Self == TweenProp.PitchScale {
  static var pitchScale: TweenProp.PitchScale.Type { TweenProp.PitchScale.self }
}
