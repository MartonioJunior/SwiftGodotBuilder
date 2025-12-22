import SwiftGodot

public extension GNode where T: Node {
  // MARK: - On Ready Animation

  /// Runs a tween animation when the node becomes ready.
  ///
  /// Automatically waits one frame after ready to ensure the node is fully initialized.
  ///
  /// ## Usage
  /// ```swift
  /// Label$()
  ///   .modulate(Color(r: 1, g: 1, b: 1, a: 0))
  ///   .tweenOnReady { label in
  ///     label.tween(.alpha(1.0), duration: 0.3).ease(.out)
  ///   }
  /// ```
  ///
  /// - Parameter handler: Closure called with the node to perform animations
  /// - Returns: The modified GNode
  func tweenOnReady(_ handler: @escaping (T) -> Void) -> Self {
    onReady { node in
      Engine.onNextFrame {
        handler(node)
      }
    }
  }

  // MARK: - Toggle Animations (Bool State)

  /// Animates a Vector2 property when a bool state toggles.
  ///
  /// When the state becomes true, animates to `whenTrue`. When false, animates to `whenFalse`.
  /// Previous animations are automatically killed when the state changes.
  ///
  /// ## Usage
  /// ```swift
  /// @State var isHovered = false
  ///
  /// Button$()
  ///   .tweenToggle($isHovered, .scale,
  ///                whenTrue: [1.1, 1.1], whenFalse: [1.0, 1.0],
  ///                duration: 0.1)
  ///   .onSignal(\.mouseEntered) { _ in isHovered = true }
  ///   .onSignal(\.mouseExited) { _ in isHovered = false }
  /// ```
  ///
  /// - Parameters:
  ///   - state: The bool state to observe
  ///   - property: The property type to animate
  ///   - whenTrue: Value to animate to when state is true
  ///   - whenFalse: Value to animate to when state is false
  ///   - duration: Animation duration in seconds
  ///   - ease: Easing type (default: .out)
  ///   - trans: Transition type (default: .quad)
  /// - Returns: The modified GNode
  func tweenToggle<P: TweenableProperty>(
    _ state: GState<Bool>,
    _: P.Type,
    whenTrue: P.Value,
    whenFalse: P.Value,
    duration: Double = 0.1,
    ease: Tween.EaseType = .out,
    trans: Tween.TransitionType = .quad
  ) -> Self where P.Value == Vector2 {
    var currentTween: Tween?
    return configure { node in
      state.observe(owner: node) { isTrue in
        currentTween?.kill()
        currentTween = node.createTween()
        let target = isTrue ? whenTrue : whenFalse
        _ = currentTween?.tweenProperty(
          object: node,
          property: NodePath(stringLiteral: P.propertyName),
          finalVal: Variant(target),
          duration: duration
        )?.setEase(ease)?.setTrans(trans)
      }
    }
  }

  /// Animates a Float property when a bool state toggles.
  func tweenToggle<P: TweenableProperty>(
    _ state: GState<Bool>,
    _: P.Type,
    whenTrue: P.Value,
    whenFalse: P.Value,
    duration: Double = 0.1,
    ease: Tween.EaseType = .out,
    trans: Tween.TransitionType = .quad
  ) -> Self where P.Value == Float {
    var currentTween: Tween?
    return configure { node in
      state.observe(owner: node) { isTrue in
        currentTween?.kill()
        currentTween = node.createTween()
        let target = isTrue ? whenTrue : whenFalse
        _ = currentTween?.tweenProperty(
          object: node,
          property: NodePath(stringLiteral: P.propertyName),
          finalVal: Variant(target),
          duration: duration
        )?.setEase(ease)?.setTrans(trans)
      }
    }
  }

  /// Animates a Color property when a bool state toggles.
  func tweenToggle<P: TweenableProperty>(
    _ state: GState<Bool>,
    _: P.Type,
    whenTrue: P.Value,
    whenFalse: P.Value,
    duration: Double = 0.1,
    ease: Tween.EaseType = .out,
    trans: Tween.TransitionType = .quad
  ) -> Self where P.Value == Color {
    var currentTween: Tween?
    return configure { node in
      state.observe(owner: node) { isTrue in
        currentTween?.kill()
        currentTween = node.createTween()
        let target = isTrue ? whenTrue : whenFalse
        _ = currentTween?.tweenProperty(
          object: node,
          property: NodePath(stringLiteral: P.propertyName),
          finalVal: Variant(target),
          duration: duration
        )?.setEase(ease)?.setTrans(trans)
      }
    }
  }

  // MARK: - Conditional Animations (Any Equatable State)

  /// Animates when a state equals a specific value.
  ///
  /// Provides custom animation closures for when the condition is met and not met.
  ///
  /// ## Usage
  /// ```swift
  /// @State var selectedTab = 0
  ///
  /// TabButton$()
  ///   .tweenWhen($selectedTab, equals: 0) { btn in
  ///     btn.tween(.scale([1.1, 1.1]), duration: 0.1)
  ///       .ease(.out)
  ///   } otherwise: { btn in
  ///     btn.tween(.scale([1.0, 1.0]), duration: 0.1)
  ///       .ease(.out)
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - state: The state to observe
  ///   - value: The value to compare against
  ///   - onMatch: Closure called when state equals value
  ///   - otherwise: Closure called when state doesn't equal value
  /// - Returns: The modified GNode
  func tweenWhen<V: Equatable>(
    _ state: GState<V>,
    equals value: V,
    _ onMatch: @escaping (T) -> Void,
    otherwise onMismatch: @escaping (T) -> Void
  ) -> Self {
    configure { node in
      state.observe(owner: node) { currentValue in
        if currentValue == value {
          onMatch(node)
        } else {
          onMismatch(node)
        }
      }
    }
  }

  /// Animates based on any state change with a custom handler.
  ///
  /// ## Usage
  /// ```swift
  /// @State var health = 100
  ///
  /// HealthBar$()
  ///   .tweenOnChange($health) { bar, newHealth in
  ///     bar.tween(.scaleX(Float(newHealth) / 100.0), duration: 0.2)
  ///       .ease(.out)
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - state: The state to observe
  ///   - handler: Closure called with the node and new value
  /// - Returns: The modified GNode
  func tweenOnChange<V: Equatable>(
    _ state: GState<V>,
    _ handler: @escaping (T, V) -> Void
  ) -> Self {
    configure { node in
      state.observe(owner: node) { value in
        handler(node, value)
      }
    }
  }
}
