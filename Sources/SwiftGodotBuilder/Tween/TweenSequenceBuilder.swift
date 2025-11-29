import SwiftGodot

// MARK: - Tween Sequence Context

/// A chainable context for building tween sequences.
///
/// ## Usage
/// ```swift
/// btn.tween { seq in
///   seq.to(.scale([1.0, 0.8]), duration: 0.05)
///      .trans(.quad).ease(.out)
///      .to(.scale([1.0, 1.0]), duration: 0.1)
///      .trans(.bounce).ease(.out)
/// }
/// ```
public class TweenSequenceContext {
  let node: Node
  let tween: Tween?
  private var lastTweener: PropertyTweener?

  init(node: Node) {
    self.node = node
    tween = node.createTween()
  }

  // MARK: - Primary Animation Method

  /// Adds an animation to the sequence using the enum-based property.
  ///
  /// ```swift
  /// seq.to(.scale([1.1, 1.1]), duration: 0.1)
  ///    .to(.alpha(0.5), duration: 0.2)
  ///    .to(.position([100, 200]), duration: 0.5)
  /// ```
  @discardableResult
  public func to(_ property: Anim, duration: Double) -> Self {
    lastTweener = tween?.tweenProperty(
      object: node,
      property: NodePath(stringLiteral: property.propertyName),
      finalVal: property.value,
      duration: duration
    )
    return self
  }

  // MARK: - Configuration (applies to last animation)

  /// Sets the easing type for the last added animation.
  @discardableResult
  public func ease(_ ease: Tween.EaseType) -> Self {
    _ = lastTweener?.setEase(ease)
    return self
  }

  /// Sets the transition type for the last added animation.
  @discardableResult
  public func trans(_ trans: Tween.TransitionType) -> Self {
    _ = lastTweener?.setTrans(trans)
    return self
  }

  /// Sets a delay before the last added animation starts.
  @discardableResult
  public func delay(_ seconds: Double) -> Self {
    _ = lastTweener?.setDelay(seconds)
    return self
  }

  /// Sets a custom starting value for the last added animation.
  @discardableResult
  public func from(_ property: Anim) -> Self {
    _ = lastTweener?.from(value: property.value)
    return self
  }

  /// Makes the last animation's final value relative to the starting value.
  @discardableResult
  public func asRelative() -> Self {
    _ = lastTweener?.asRelative()
    return self
  }

  // MARK: - Wait/Interval

  /// Adds a wait interval before the next animation.
  @discardableResult
  public func wait(_ seconds: Double) -> Self {
    _ = tween?.tweenInterval(time: seconds)
    return self
  }
}

// MARK: - Node Extension

public extension Node {
  /// Creates a tween sequence using a chainable builder closure.
  ///
  /// ## Usage
  /// ```swift
  /// // Bounce effect
  /// btn.tween { seq in
  ///   seq.to(.scale([1.0, 0.8]), duration: 0.05)
  ///      .trans(.quad).ease(.out)
  ///      .to(.scale([1.0, 1.15]), duration: 0.08)
  ///      .trans(.quad).ease(.out)
  ///      .to(.scale([1.0, 1.0]), duration: 0.12)
  ///      .trans(.bounce).ease(.out)
  /// }
  ///
  /// // Looping pulse
  /// icon.tween { seq in
  ///   seq.to(.scale([1.05, 1.05]), duration: 0.5)
  ///      .ease(.inOut).trans(.sine)
  ///      .to(.scale([1.0, 1.0]), duration: 0.5)
  ///      .ease(.inOut).trans(.sine)
  /// }
  /// .loop()
  ///
  /// // Fade and move
  /// panel.tween { seq in
  ///   seq.to(.alpha(0.0), duration: 0.3)
  ///      .to(.positionY(100), duration: 0.3)
  /// }
  /// ```
  @discardableResult
  func tween(_ builder: (TweenSequenceContext) -> Void) -> SequenceHandle {
    let context = TweenSequenceContext(node: self)
    builder(context)
    return SequenceHandle(tween: context.tween)
  }
}
