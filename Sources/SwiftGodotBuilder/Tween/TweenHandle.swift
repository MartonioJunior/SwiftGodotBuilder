import SwiftGodot

// MARK: - Tween Handle

/// A chainable handle for configuring a property tween.
///
/// `TweenHandle` wraps a Godot `Tween` and `PropertyTweener`, providing a fluent
/// API for configuring animation properties like easing, transitions, and callbacks.
///
/// ## Usage
/// ```swift
/// // Chain configuration methods
/// node.tween(.scale([1.1, 1.1]), duration: 0.1)
///   .ease(.out)
///   .trans(.quad)
///   .delay(0.1)
///   .onFinished { print("done") }
///
/// // Start from a specific value
/// node.tween(.alpha(1.0), duration: 0.3)
///   .from(0.0)
///   .ease(.out)
/// ```
public struct TweenHandle: Equatable {
  /// The underlying Godot tween object.
  public let tween: Tween?

  /// The property tweener for this animation.
  public let tweener: PropertyTweener?

  public static func == (lhs: TweenHandle, rhs: TweenHandle) -> Bool {
    lhs.tween === rhs.tween && lhs.tweener === rhs.tweener
  }

  /// Creates a new tween handle.
  ///
  /// - Parameters:
  ///   - tween: The Godot tween object
  ///   - tweener: The property tweener for this animation
  public init(tween: Tween?, tweener: PropertyTweener?) {
    self.tween = tween
    self.tweener = tweener
  }

  // MARK: - Easing Configuration

  /// Sets the easing type for this animation.
  ///
  /// Easing affects the acceleration curve of the animation:
  /// - `.in`: Starts slow, accelerates
  /// - `.out`: Starts fast, decelerates
  /// - `.inOut`: Slow at both ends, fast in middle
  /// - `.outIn`: Fast at both ends, slow in middle
  ///
  /// - Parameter ease: The easing type to use
  /// - Returns: Self for chaining
  @discardableResult
  public func ease(_ ease: Tween.EaseType) -> Self {
    _ = tweener?.setEase(ease)
    return self
  }

  /// Sets the transition type for this animation.
  ///
  /// Transition type defines the mathematical curve:
  /// - `.linear`: Constant speed
  /// - `.quad`: Quadratic (x^2)
  /// - `.cubic`: Cubic (x^3)
  /// - `.sine`: Sinusoidal
  /// - `.bounce`: Bouncy effect
  /// - `.elastic`: Springy overshoot
  /// - `.back`: Slight overshoot
  ///
  /// - Parameter trans: The transition type to use
  /// - Returns: Self for chaining
  @discardableResult
  public func trans(_ trans: Tween.TransitionType) -> Self {
    _ = tweener?.setTrans(trans)
    return self
  }

  // MARK: - Timing Configuration

  /// Sets a delay before this animation starts.
  ///
  /// - Parameter seconds: Delay in seconds before the animation begins
  /// - Returns: Self for chaining
  @discardableResult
  public func delay(_ seconds: Double) -> Self {
    _ = tweener?.setDelay(seconds)
    return self
  }

  // MARK: - Value Configuration

  /// Sets a custom starting value for this animation.
  ///
  /// By default, animations start from the property's current value.
  /// Use `from()` to override this with a specific starting value.
  ///
  /// - Parameter value: The starting value for the animation
  /// - Returns: Self for chaining
  @discardableResult
  public func from(_ value: Vector2) -> Self {
    _ = tweener?.from(value: Variant(value))
    return self
  }

  /// Sets a custom starting value for this animation (Float).
  @discardableResult
  public func from(_ value: Float) -> Self {
    _ = tweener?.from(value: Variant(value))
    return self
  }

  /// Sets a custom starting value for this animation (Double).
  @discardableResult
  public func from(_ value: Double) -> Self {
    _ = tweener?.from(value: Variant(value))
    return self
  }

  /// Sets a custom starting value for this animation (Color).
  @discardableResult
  public func from(_ value: Color) -> Self {
    _ = tweener?.from(value: Variant(value))
    return self
  }

  /// Makes the animation start from the current property value.
  ///
  /// This is equivalent to calling `from()` with the current value,
  /// useful when chaining multiple animations on the same property.
  ///
  /// - Returns: Self for chaining
  @discardableResult
  public func fromCurrent() -> Self {
    _ = tweener?.fromCurrent()
    return self
  }

  /// Makes the final value relative to the starting value.
  ///
  /// Instead of animating TO a value, animates BY a value.
  /// For example, `.asRelative()` with `to: [10, 0]` will move
  /// 10 units to the right from wherever the node currently is.
  ///
  /// - Returns: Self for chaining
  @discardableResult
  public func asRelative() -> Self {
    _ = tweener?.asRelative()
    return self
  }

  // MARK: - Callbacks

  /// Registers a callback to be called when the animation finishes.
  ///
  /// - Parameter handler: Closure to execute when animation completes
  /// - Returns: Self for chaining
  @discardableResult
  public func onFinished(_ handler: @escaping () -> Void) -> Self {
    _ = tween?.finished.connect { handler() }
    return self
  }

  // MARK: - Tween Control

  /// Stops and frees the tween.
  ///
  /// Call this to cancel an in-progress animation.
  public func kill() {
    tween?.kill()
  }

  /// Pauses the tween.
  public func pause() {
    tween?.pause()
  }

  /// Resumes a paused tween.
  public func play() {
    tween?.play()
  }

  /// Stops the tween without freeing it.
  public func stop() {
    tween?.stop()
  }

  /// Returns whether the tween is currently running.
  public var isRunning: Bool {
    tween?.isRunning() ?? false
  }

  /// Returns whether the tween is valid.
  public var isValid: Bool {
    tween?.isValid() ?? false
  }
}

// MARK: - Sequence Handle

/// A handle for a tween sequence containing multiple animations.
///
/// `SequenceHandle` wraps a `Tween` that contains multiple `PropertyTweener`s,
/// providing configuration for the entire sequence.
///
/// ## Usage
/// ```swift
/// node.tween { seq in
///   seq.to(.scale([0.8, 1.2]), duration: 0.05)
///      .to(.scale([1.0, 1.0]), duration: 0.1)
/// }
/// .loop(3)
/// .onFinished { print("sequence done") }
/// ```
public struct SequenceHandle: Equatable {
  /// The underlying Godot tween object.
  public let tween: Tween?

  public static func == (lhs: SequenceHandle, rhs: SequenceHandle) -> Bool {
    lhs.tween === rhs.tween
  }

  /// Creates a new sequence handle.
  ///
  /// - Parameter tween: The Godot tween object containing the sequence
  public init(tween: Tween?) {
    self.tween = tween
  }

  // MARK: - Loop Configuration

  /// Sets the number of times to loop the sequence.
  ///
  /// - Parameter count: Number of loops (nil or omitted = infinite)
  /// - Returns: Self for chaining
  @discardableResult
  public func loop(_ count: Int? = nil) -> Self {
    _ = tween?.setLoops(Int32(count ?? 0))
    return self
  }

  // MARK: - Playback Configuration

  /// Sets parallel mode where all tweeners run simultaneously.
  ///
  /// By default, tweeners in a sequence run one after another.
  /// Call this to make them all start at the same time.
  ///
  /// - Returns: Self for chaining
  @discardableResult
  public func parallel() -> Self {
    _ = tween?.setParallel(true)
    return self
  }

  /// Sets the playback speed multiplier.
  ///
  /// - Parameter speed: Speed multiplier (1.0 = normal, 2.0 = double speed)
  /// - Returns: Self for chaining
  @discardableResult
  public func speed(_ speed: Double) -> Self {
    _ = tween?.setSpeedScale(speed: speed)
    return self
  }

  // MARK: - Callbacks

  /// Registers a callback to be called when the sequence finishes.
  ///
  /// For looping sequences, this is called after each complete loop.
  ///
  /// - Parameter handler: Closure to execute when sequence completes
  /// - Returns: Self for chaining
  @discardableResult
  public func onFinished(_ handler: @escaping () -> Void) -> Self {
    _ = tween?.finished.connect { handler() }
    return self
  }

  /// Registers a callback for each loop completion.
  ///
  /// - Parameter handler: Closure receiving the loop count
  /// - Returns: Self for chaining
  @discardableResult
  public func onLoopFinished(_ handler: @escaping (Int) -> Void) -> Self {
    _ = tween?.loopFinished.connect { loopCount in
      handler(Int(loopCount))
    }
    return self
  }

  // MARK: - Tween Control

  /// Stops and frees the tween.
  public func kill() {
    tween?.kill()
  }

  /// Pauses the tween.
  public func pause() {
    tween?.pause()
  }

  /// Resumes a paused tween.
  public func play() {
    tween?.play()
  }

  /// Stops the tween without freeing it.
  public func stop() {
    tween?.stop()
  }

  /// Returns whether the tween is currently running.
  public var isRunning: Bool {
    tween?.isRunning() ?? false
  }

  /// Returns whether the tween is valid.
  public var isValid: Bool {
    tween?.isValid() ?? false
  }
}
