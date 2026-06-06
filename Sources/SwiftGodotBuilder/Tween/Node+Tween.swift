import SwiftGodot

// MARK: - Node Tween Extensions

public extension Node {
  // MARK: - One-Shot Tweens

  /// Tweens a property to a target value.
  ///
  /// This creates a fire-and-forget animation that automatically manages its own lifecycle.
  /// The animation starts immediately and the tween is freed when complete.
  ///
  /// ## Usage
  /// ```swift
  /// // Simple scale tween
  /// btn.tween(.scale([1.1, 1.1]), duration: 0.1)
  ///
  /// // With easing and transition
  /// sprite.tween(.position([100, 200]), duration: 0.5)
  ///   .ease(.out)
  ///   .trans(.quad)
  ///
  /// // Fade out and remove
  /// enemy.tween(.alpha(0.0), duration: 0.3)
  ///   .onFinished { enemy.queueFree() }
  /// ```
  ///
  /// - Parameters:
  ///   - property: The property to tween (e.g., `.scale([1.1, 1.1])`)
  ///   - duration: Animation duration in seconds
  /// - Returns: A `TweenHandle` for chaining configuration
  @discardableResult
  func tween(_ property: Anim, duration: Double) -> TweenHandle {
    let tween = createTween()
    let tweener = tween.tweenProperty(
      object: self,
      property: NodePath(stringLiteral: property.propertyName),
      finalVal: property.value,
      duration: duration
    )
    return TweenHandle(tween: tween, tweener: tweener)
  }

  /// Creates a managed tween that kills any previous one.
  ///
  /// ```swift
  /// @State var currentTween: TweenHandle?
  /// currentTween = btn.tween(.scale([1.1, 1.1]), duration: 0.1, killing: currentTween)
  /// ```
  @discardableResult
  func tween(_ property: Anim, duration: Double, killing previous: TweenHandle?) -> TweenHandle {
    previous?.kill()
    return tween(property, duration: duration)
  }

  // MARK: - String-based Property Tween

  /// Tweens a property by name (for custom/advanced properties).
  @discardableResult
  func tween(property: String, to value: Variant, duration: Double) -> TweenHandle {
    let tween = createTween()
    let tweener = tween.tweenProperty(
      object: self,
      property: NodePath(stringLiteral: property),
      finalVal: value,
      duration: duration
    )
    return TweenHandle(tween: tween, tweener: tweener)
  }
}
