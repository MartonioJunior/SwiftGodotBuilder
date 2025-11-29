import SwiftGodot

// MARK: - Anim Property Enum

/// A type-safe enum representing animatable properties with their target values.
///
/// This provides clean, SwiftUI-style syntax for tweening:
/// ```swift
/// node.tween(.scale([1.1, 1.1]), duration: 0.1)
///
/// node.tween { seq in
///   seq.to(.scale([1.0, 0.8]), duration: 0.05)
///      .to(.scale([1.0, 1.0]), duration: 0.1)
/// }
/// ```
public enum Anim {
  // MARK: - Scale

  case scale(Vector2)
  case scaleX(Float)
  case scaleY(Float)

  // MARK: - Position

  case position(Vector2)
  case positionX(Float)
  case positionY(Float)
  case globalPosition(Vector2)

  // MARK: - Rotation

  case rotation(Float)
  case rotationDegrees(Float)

  // MARK: - Color/Alpha

  case modulate(Color)
  case alpha(Float)
  case selfModulate(Color)
  case selfAlpha(Float)

  // MARK: - Size (Controls)

  case size(Vector2)
  case minSize(Vector2)

  // MARK: - Other

  case pivotOffset(Vector2)
  case skew(Float)

  // MARK: - Audio

  case volumeDb(Float)
  case pitchScale(Float)

  // MARK: - Custom

  case custom(property: String, value: Variant)

  /// The Godot property path string.
  public var propertyName: String {
    switch self {
    case .scale: return "scale"
    case .scaleX: return "scale:x"
    case .scaleY: return "scale:y"
    case .position: return "position"
    case .positionX: return "position:x"
    case .positionY: return "position:y"
    case .globalPosition: return "global_position"
    case .rotation: return "rotation"
    case .rotationDegrees: return "rotation_degrees"
    case .modulate: return "modulate"
    case .alpha: return "modulate:a"
    case .selfModulate: return "self_modulate"
    case .selfAlpha: return "self_modulate:a"
    case .size: return "size"
    case .minSize: return "custom_minimum_size"
    case .pivotOffset: return "pivot_offset"
    case .skew: return "skew"
    case .volumeDb: return "volume_db"
    case .pitchScale: return "pitch_scale"
    case let .custom(property, _): return property
    }
  }

  /// The target value as a Variant.
  public var value: Variant {
    switch self {
    case let .scale(v): return Variant(v)
    case let .scaleX(v): return Variant(v)
    case let .scaleY(v): return Variant(v)
    case let .position(v): return Variant(v)
    case let .positionX(v): return Variant(v)
    case let .positionY(v): return Variant(v)
    case let .globalPosition(v): return Variant(v)
    case let .rotation(v): return Variant(v)
    case let .rotationDegrees(v): return Variant(v)
    case let .modulate(v): return Variant(v)
    case let .alpha(v): return Variant(v)
    case let .selfModulate(v): return Variant(v)
    case let .selfAlpha(v): return Variant(v)
    case let .size(v): return Variant(v)
    case let .minSize(v): return Variant(v)
    case let .pivotOffset(v): return Variant(v)
    case let .skew(v): return Variant(v)
    case let .volumeDb(v): return Variant(v)
    case let .pitchScale(v): return Variant(v)
    case let .custom(_, v): return v
    }
  }
}
