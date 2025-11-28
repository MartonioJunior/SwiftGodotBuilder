import Foundation
import Observation
import SwiftGodot

// MARK: - Composable Effect System

/// A composable effect that can be applied to an SVGSprite.
///
/// Effects are categorized by what they modify:
/// - **Size effects**: Modify `sprite.size` (pulse)
/// - **Color effects**: Modify fill/stroke colors (colorCycle, strokeCycle)
/// - **Vertex effects**: Modify vertex positions (wobble, explode, wave)
///
/// Multiple effects of different categories can be combined. Vertex effects
/// are chained so each transformation builds on the previous.
public protocol SVGEffectProtocol {
  /// Applies the effect for the current frame.
  /// - Parameters:
  ///   - sprite: The SVGSprite to modify
  ///   - state: Shared effect state (time, original vertices, centers)
  ///   - currentVerts: Current vertex arrays (for chaining vertex effects)
  /// - Returns: Updated vertex arrays (pass through for non-vertex effects)
  func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]]

  /// Called each frame to update time-based state.
  func update(delta: Double, state: SVGEffectSharedState)
}

/// Shared state for all effects on an SVGSprite.
public final class SVGEffectSharedState {
  var time: Double = 0
  var originalVerts: [[Vector2]] = []
  var centers: [Vector2] = []
  private var lastRebuildCount: Int = -1

  /// Initializes or re-initializes vertex data when sprite rebuilds.
  /// Returns true if successfully initialized, false if sprite has no elements yet.
  func initializeIfNeeded(from sprite: SVGSprite) -> Bool {
    // Check if sprite was rebuilt - if so, clear cached data
    if sprite.rebuildCount != lastRebuildCount {
      originalVerts.removeAll()
      centers.removeAll()
      lastRebuildCount = sprite.rebuildCount
    }

    // Already initialized for current rebuild
    guard originalVerts.isEmpty else { return true }

    let count = sprite.getElementCount()
    // Wait for elements to be built before initializing
    guard count > 0 else { return false }

    for i in 0 ..< count {
      if let verts = sprite.getVertices(i) {
        var arr: [Vector2] = []
        var center = Vector2.zero
        for j in 0 ..< Int(verts.size()) {
          arr.append(verts[j])
          center = center + verts[j]
        }
        if !arr.isEmpty {
          center = center / Double(arr.count)
        }
        originalVerts.append(arr)
        centers.append(center)
      }
    }
    return !originalVerts.isEmpty
  }
}

// MARK: - Effect Types

/// Pulse effect - oscillates sprite scale via vertex transformation.
///
/// Unlike modifying `sprite.size` (which triggers rebuild), this scales
/// vertices directly for smooth animation without rebuilding.
public struct SVGPulse: SVGEffectProtocol {
  let speedProvider: () -> Double
  let amplitude: Double

  /// Creates a pulse effect.
  /// - Parameters:
  ///   - speed: Oscillation speed (radians per second)
  ///   - amplitude: Scale variation (0.2 = ±20% size change)
  public init(speed: Double = 2.0, amplitude: Double = 0.2) {
    self.speedProvider = { speed }
    self.amplitude = amplitude
  }

  public init<O: AnyObject & Observable>(
    speed: ObservableProperty<O, Double>,
    amplitude: Double = 0.2
  ) {
    self.speedProvider = { speed.value }
    self.amplitude = amplitude
  }

  public init(speed: GState<Double>, amplitude: Double = 0.2) {
    self.speedProvider = { speed.wrappedValue }
    self.amplitude = amplitude
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let scale = Float(1.0 + amplitude * sin(state.time * speedProvider()))
    var result: [[Vector2]] = []

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let center = i < state.centers.count ? state.centers[i] : .zero
      var scaled: [Vector2] = []
      for v in orig {
        let fromCenter = v - center
        scaled.append(center + fromCenter * scale)
      }
      result.append(scaled)
    }

    return result
  }
}

// MARK: - Color Interpolation Helper

/// Interpolates between colors in an array based on a 0-1 progress value.
/// Automatically loops back to the first color for seamless cycling.
private func interpolateColors(_ colors: [Color], at progress: Double) -> Color {
  guard colors.count > 1 else { return colors.first ?? .white }

  // Treat as a loop: last segment goes from last color back to first
  let segmentCount = colors.count
  let scaledProgress = progress * Double(segmentCount)
  let segmentIndex = Int(scaledProgress) % segmentCount
  let segmentProgress = Float(scaledProgress - Double(Int(scaledProgress)))

  let from = colors[segmentIndex]
  let to = colors[(segmentIndex + 1) % segmentCount]

  return Color(
    r: from.red + (to.red - from.red) * segmentProgress,
    g: from.green + (to.green - from.green) * segmentProgress,
    b: from.blue + (to.blue - from.blue) * segmentProgress,
    a: from.alpha + (to.alpha - from.alpha) * segmentProgress
  )
}

/// Color cycle effect - cycles fill color through an array of colors.
public struct SVGColorCycle: SVGEffectProtocol {
  let colors: [Color]
  let speed: Double
  let elementIndex: Int

  /// Cycles through the provided colors.
  /// - Parameters:
  ///   - colors: Colors to cycle through (interpolated smoothly)
  ///   - speed: Cycles per second
  ///   - elementIndex: Which SVG element to colorize
  public init(_ colors: [Color], speed: Double = 0.5, elementIndex: Int = 0) {
    self.colors = colors
    self.speed = speed
    self.elementIndex = elementIndex
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    var progress = (state.time * speed).truncatingRemainder(dividingBy: 1.0)
    if progress < 0 { progress += 1 }
    let color = interpolateColors(colors, at: progress)
    sprite.setColor(color, forElement: elementIndex)
    return currentVerts
  }
}

/// Stroke cycle effect - cycles stroke color through an array of colors.
public struct SVGStrokeCycle: SVGEffectProtocol {
  let colors: [Color]
  let speed: Double
  let elementIndex: Int

  /// Cycles stroke through the provided colors.
  /// - Parameters:
  ///   - colors: Colors to cycle through (interpolated smoothly)
  ///   - speed: Cycles per second
  ///   - elementIndex: Which SVG element to colorize
  public init(_ colors: [Color], speed: Double = 0.5, elementIndex: Int = 0) {
    self.colors = colors
    self.speed = speed
    self.elementIndex = elementIndex
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    var progress = (state.time * speed).truncatingRemainder(dividingBy: 1.0)
    if progress < 0 { progress += 1 }
    let color = interpolateColors(colors, at: progress)
    sprite.setStrokeColor(color, forElement: elementIndex)
    return currentVerts
  }
}

/// Dual color cycle effect - cycles both fill and stroke through color arrays.
public struct SVGDualColorCycle: SVGEffectProtocol {
  let fillColors: [Color]
  let strokeColors: [Color]
  let fillSpeed: Double
  let strokeSpeed: Double
  let elementIndex: Int

  /// Cycles fill and stroke through separate color arrays.
  /// - Parameters:
  ///   - fillColors: Colors to cycle fill through
  ///   - strokeColors: Colors to cycle stroke through
  ///   - fillSpeed: Fill cycles per second
  ///   - strokeSpeed: Stroke cycles per second
  ///   - elementIndex: Which SVG element to colorize
  public init(
    fill fillColors: [Color],
    stroke strokeColors: [Color],
    fillSpeed: Double = 0.5,
    strokeSpeed: Double = 0.7,
    elementIndex: Int = 0
  ) {
    self.fillColors = fillColors
    self.strokeColors = strokeColors
    self.fillSpeed = fillSpeed
    self.strokeSpeed = strokeSpeed
    self.elementIndex = elementIndex
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    var fillProgress = (state.time * fillSpeed).truncatingRemainder(dividingBy: 1.0)
    var strokeProgress = (state.time * strokeSpeed).truncatingRemainder(dividingBy: 1.0)
    if fillProgress < 0 { fillProgress += 1 }
    if strokeProgress < 0 { strokeProgress += 1 }
    sprite.setColor(interpolateColors(fillColors, at: fillProgress), forElement: elementIndex)
    sprite.setStrokeColor(interpolateColors(strokeColors, at: strokeProgress), forElement: elementIndex)
    return currentVerts
  }
}

/// Wobble effect - radial vertex deformation from center.
public struct SVGWobble: SVGEffectProtocol {
  let amountProvider: () -> Double
  let speed: Double

  public init(amount: Double = 5.0, speed: Double = 4.0) {
    self.amountProvider = { amount }
    self.speed = speed
  }

  public init<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 4.0) {
    self.amountProvider = { amount.value }
    self.speed = speed
  }

  public init(amount: GState<Double>, speed: Double = 4.0) {
    self.amountProvider = { amount.wrappedValue }
    self.speed = speed
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let wobbleAmount = amountProvider()
    var result: [[Vector2]] = []

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []
      for (j, v) in orig.enumerated() {
        let dir = (v - center).normalized()
        let phase = Double(j) * 0.3
        let offset = Float(sin(state.time * speed + phase) * wobbleAmount)
        transformed.append(v + dir * offset)
      }
      result.append(transformed)
    }

    return result
  }
}

/// Explode effect - vertices expand outward from center.
public struct SVGExplode: SVGEffectProtocol {
  let progressProvider: () -> Double
  let scale: Double

  public init(progress: Double, scale: Double = 50.0) {
    self.progressProvider = { progress }
    self.scale = scale
  }

  public init<O: AnyObject & Observable>(progress: ObservableProperty<O, Double>, scale: Double = 50.0) {
    self.progressProvider = { progress.value }
    self.scale = scale
  }

  public init(progress: GState<Double>, scale: Double = 50.0) {
    self.progressProvider = { progress.wrappedValue }
    self.scale = scale
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let expansion = Float(progressProvider() * scale)
    var result: [[Vector2]] = []

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []
      for v in orig {
        let dir = (v - center).normalized()
        transformed.append(v + dir * expansion)
      }
      result.append(transformed)
    }

    return result
  }
}

/// Wave effect - horizontal wave deformation based on Y position.
public struct SVGWave: SVGEffectProtocol {
  let amplitudeProvider: () -> Double
  let frequency: Double
  let speed: Double

  public init(amplitude: Double = 3.0, frequency: Double = 0.2, speed: Double = 3.0) {
    self.amplitudeProvider = { amplitude }
    self.frequency = frequency
    self.speed = speed
  }

  public init<O: AnyObject & Observable>(amplitude: ObservableProperty<O, Double>, frequency: Double = 0.2, speed: Double = 3.0) {
    self.amplitudeProvider = { amplitude.value }
    self.frequency = frequency
    self.speed = speed
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let amplitude = amplitudeProvider()
    var result: [[Vector2]] = []

    for orig in currentVerts {
      var transformed: [Vector2] = []
      for v in orig {
        let waveOffset = Float(sin(state.time * speed + Double(v.y) * frequency) * amplitude)
        transformed.append(Vector2(x: v.x + waveOffset, y: v.y))
      }
      result.append(transformed)
    }

    return result
  }
}

// MARK: - Game-Focused Vertex Effects

/// Inflate effect - uniform breathing/pulsing expansion from center.
///
/// Unlike explode (one-way expansion), inflate oscillates like breathing.
/// Vertices expand and contract uniformly from their element's center.
public struct SVGInflate: SVGEffectProtocol {
  let amountProvider: () -> Double
  let speed: Double

  /// Creates an inflate effect with constant parameters.
  /// - Parameters:
  ///   - amount: Maximum expansion distance in pixels
  ///   - speed: Breathing rate (oscillations per second * 2π)
  public init(amount: Double = 5.0, speed: Double = 2.0) {
    self.amountProvider = { amount }
    self.speed = speed
  }

  public init<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 2.0) {
    self.amountProvider = { amount.value }
    self.speed = speed
  }

  public init(amount: GState<Double>, speed: Double = 2.0) {
    self.amountProvider = { amount.wrappedValue }
    self.speed = speed
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let inflateAmount = amountProvider()
    let scale = Float(sin(state.time * speed) * inflateAmount)
    var result: [[Vector2]] = []

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []
      for v in orig {
        let dir = (v - center).normalized()
        transformed.append(v + dir * scale)
      }
      result.append(transformed)
    }

    return result
  }
}

/// Skew effect - shears/leans the shape based on Y position.
///
/// Applies horizontal displacement proportional to vertical position,
/// creating a leaning or wind-blown effect.
public struct SVGSkew: SVGEffectProtocol {
  let amountProvider: () -> Double
  let speed: Double
  let animated: Bool

  /// Creates a skew effect.
  /// - Parameters:
  ///   - amount: Skew factor (pixels of horizontal offset per pixel of height)
  ///   - speed: Animation speed (0 for static skew)
  ///   - animated: Whether to oscillate the skew
  public init(amount: Double = 0.3, speed: Double = 2.0, animated: Bool = true) {
    self.amountProvider = { amount }
    self.speed = speed
    self.animated = animated
  }

  public init<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 2.0, animated: Bool = true) {
    self.amountProvider = { amount.value }
    self.speed = speed
    self.animated = animated
  }

  public init(amount: GState<Double>, speed: Double = 2.0, animated: Bool = true) {
    self.amountProvider = { amount.wrappedValue }
    self.speed = speed
    self.animated = animated
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let baseAmount = amountProvider()
    let skewAmount = animated ? Float(sin(state.time * speed) * baseAmount) : Float(baseAmount)
    var result: [[Vector2]] = []

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []
      for v in orig {
        // Offset X based on distance from center Y
        let yOffset = v.y - center.y
        let xShift = yOffset * skewAmount
        transformed.append(Vector2(x: v.x + xShift, y: v.y))
      }
      result.append(transformed)
    }

    return result
  }
}

/// Noise effect - random per-vertex displacement for electric/glitch feel.
///
/// Each vertex gets deterministic pseudo-random displacement that changes over time.
/// Uses sine-based noise for smooth, repeatable randomness.
public struct SVGNoise: SVGEffectProtocol {
  let amountProvider: () -> Double
  let speed: Double

  /// Creates a noise effect.
  /// - Parameters:
  ///   - amount: Maximum displacement in pixels
  ///   - speed: How fast the noise changes
  public init(amount: Double = 2.0, speed: Double = 10.0) {
    self.amountProvider = { amount }
    self.speed = speed
  }

  public init<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 10.0) {
    self.amountProvider = { amount.value }
    self.speed = speed
  }

  public init(amount: GState<Double>, speed: Double = 10.0) {
    self.amountProvider = { amount.wrappedValue }
    self.speed = speed
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let noiseAmount = amountProvider()
    var result: [[Vector2]] = []

    // Global offset for ALL paths - keeps compound shapes (outer + holes) together
    let globalOffsetX = Float(sin(state.time * speed) * noiseAmount * 0.4)
    let globalOffsetY = Float(sin(state.time * speed * 1.3 + 1.7) * noiseAmount * 0.4)
    let globalOffset = Vector2(x: globalOffsetX, y: globalOffsetY)

    for (i, orig) in currentVerts.enumerated() {
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []

      for (j, v) in orig.enumerated() {
        // Per-vertex edge jitter outward from center (smaller amount)
        let dir = (v - center).normalized()
        let vertexSeed = Double(i * 179 + j * 127)
        let edgeNoise = Float(sin(state.time * speed * 2.3 + vertexSeed) * noiseAmount * 0.3)

        transformed.append(v + globalOffset + dir * edgeNoise)
      }
      result.append(transformed)
    }

    return result
  }
}

/// Scatter effect - each path element drifts apart from global center.
///
/// Unlike explode (which moves individual vertices), scatter moves entire
/// path elements as units, creating a disassembly effect.
public struct SVGScatter: SVGEffectProtocol {
  let progressProvider: () -> Double
  let scale: Double
  let rotate: Bool

  /// Creates a scatter effect.
  /// - Parameters:
  ///   - progress: Scatter progress (0 = together, 1 = fully scattered)
  ///   - scale: Maximum scatter distance in pixels
  ///   - rotate: Whether elements also rotate as they scatter
  public init(progress: Double, scale: Double = 50.0, rotate: Bool = true) {
    self.progressProvider = { progress }
    self.scale = scale
    self.rotate = rotate
  }

  public init<O: AnyObject & Observable>(progress: ObservableProperty<O, Double>, scale: Double = 50.0, rotate: Bool = true) {
    self.progressProvider = { progress.value }
    self.scale = scale
    self.rotate = rotate
  }

  public init(progress: GState<Double>, scale: Double = 50.0, rotate: Bool = true) {
    self.progressProvider = { progress.wrappedValue }
    self.scale = scale
    self.rotate = rotate
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let progress = Float(progressProvider())
    let scatterDist = Float(scale) * progress

    // Calculate global center from ORIGINAL vertices for stability
    var globalCenter = Vector2.zero
    var totalVerts = 0
    for verts in state.originalVerts {
      for v in verts {
        globalCenter = globalCenter + v
        totalVerts += 1
      }
    }
    if totalVerts > 0 {
      globalCenter = globalCenter / Double(totalVerts)
    }

    var result: [[Vector2]] = []

    for (i, orig) in currentVerts.enumerated() {
      let elementCenter = i < state.centers.count ? state.centers[i] : .zero

      // Direction from global center to element center
      let dir = (elementCenter - globalCenter).normalized()
      let offset = dir * scatterDist

      // Optional rotation based on element index and progress
      let rotation = rotate ? progress * Float.pi * 0.5 * Float(i % 2 == 0 ? 1 : -1) : 0

      var transformed: [Vector2] = []
      for v in orig {
        var newV = v + offset

        // Rotate around element center if enabled
        if rotate && rotation != 0 {
          let relativeToCenter = newV - elementCenter - offset
          let cosR = cos(rotation)
          let sinR = sin(rotation)
          let rotatedX = relativeToCenter.x * cosR - relativeToCenter.y * sinR
          let rotatedY = relativeToCenter.x * sinR + relativeToCenter.y * cosR
          newV = Vector2(x: rotatedX, y: rotatedY) + elementCenter + offset
        }

        transformed.append(newV)
      }
      result.append(transformed)
    }

    return result
  }
}

/// Ripple effect - concentric waves emanating from center.
///
/// Creates expanding ring distortions from the center point,
/// useful for impact effects or water ripples.
public struct SVGRipple: SVGEffectProtocol {
  let amplitudeProvider: () -> Double
  let frequency: Double
  let speed: Double

  /// Creates a ripple effect.
  /// - Parameters:
  ///   - amplitude: Wave height in pixels
  ///   - frequency: Number of ripple rings
  ///   - speed: How fast ripples expand outward
  public init(amplitude: Double = 3.0, frequency: Double = 0.3, speed: Double = 5.0) {
    self.amplitudeProvider = { amplitude }
    self.frequency = frequency
    self.speed = speed
  }

  public init<O: AnyObject & Observable>(amplitude: ObservableProperty<O, Double>, frequency: Double = 0.3, speed: Double = 5.0) {
    self.amplitudeProvider = { amplitude.value }
    self.frequency = frequency
    self.speed = speed
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let amplitude = amplitudeProvider()
    var result: [[Vector2]] = []

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []

      for v in orig {
        let dist = Double((v - center).length())
        // Ripple wave based on distance from center, moving outward over time
        let wave = sin(dist * frequency - state.time * speed) * amplitude
        let dir = (v - center).normalized()
        let offset = dir * Float(wave)
        transformed.append(v + offset)
      }
      result.append(transformed)
    }

    return result
  }
}

/// Twist effect - rotates vertices based on distance from center.
///
/// Creates a spiral/vortex distortion where outer vertices rotate
/// more than inner vertices.
public struct SVGTwist: SVGEffectProtocol {
  let amountProvider: () -> Double
  let speed: Double

  /// Creates a twist effect.
  /// - Parameters:
  ///   - amount: Maximum rotation in radians at the outer edge
  ///   - speed: Animation speed (0 for static twist)
  public init(amount: Double = 0.5, speed: Double = 2.0) {
    self.amountProvider = { amount }
    self.speed = speed
  }

  public init<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 2.0) {
    self.amountProvider = { amount.value }
    self.speed = speed
  }

  public init(amount: GState<Double>, speed: Double = 2.0) {
    self.amountProvider = { amount.wrappedValue }
    self.speed = speed
  }

  public func update(delta: Double, state: SVGEffectSharedState) {}

  public func apply(sprite: SVGSprite, state: SVGEffectSharedState, currentVerts: [[Vector2]]) -> [[Vector2]] {
    let twistAmount = amountProvider()
    let animatedTwist = Float(sin(state.time * speed) * twistAmount)
    var result: [[Vector2]] = []

    // Find max distance from ORIGINAL vertices for stable normalization
    var maxDist: Float = 1.0
    for i in 0 ..< state.originalVerts.count {
      let center = i < state.centers.count ? state.centers[i] : .zero
      for v in state.originalVerts[i] {
        let dist = Float((v - center).length())
        if dist > maxDist { maxDist = dist }
      }
    }

    for i in 0 ..< currentVerts.count {
      let orig = currentVerts[i]
      let originalVerts = i < state.originalVerts.count ? state.originalVerts[i] : orig
      let center = i < state.centers.count ? state.centers[i] : .zero
      var transformed: [Vector2] = []

      for (j, v) in orig.enumerated() {
        let relPos = v - center
        // Use original distance for stable normalization
        let originalRelPos = j < originalVerts.count ? originalVerts[j] - center : relPos
        let dist = Float(originalRelPos.length())
        let normalizedDist = dist / maxDist

        // Rotation amount increases with distance from center
        let rotation = animatedTwist * normalizedDist

        let cosR = cos(rotation)
        let sinR = sin(rotation)
        let rotatedX = relPos.x * cosR - relPos.y * sinR
        let rotatedY = relPos.x * sinR + relPos.y * cosR

        transformed.append(Vector2(x: rotatedX, y: rotatedY) + center)
      }
      result.append(transformed)
    }

    return result
  }
}

// MARK: - Effect Builder

/// Result builder for composing multiple SVG effects.
@resultBuilder
public struct SVGEffectBuilder {
  public static func buildBlock(_ effects: any SVGEffectProtocol...) -> [any SVGEffectProtocol] {
    effects
  }

  public static func buildArray(_ effects: [[any SVGEffectProtocol]]) -> [any SVGEffectProtocol] {
    effects.flatMap { $0 }
  }

  public static func buildOptional(_ effects: [any SVGEffectProtocol]?) -> [any SVGEffectProtocol] {
    effects ?? []
  }

  public static func buildEither(first effects: [any SVGEffectProtocol]) -> [any SVGEffectProtocol] {
    effects
  }

  public static func buildEither(second effects: [any SVGEffectProtocol]) -> [any SVGEffectProtocol] {
    effects
  }
}

// MARK: - GNode Extension for Composable Effects

public extension GNode where T == SVGSprite {
  /// Applies multiple composable effects to the SVGSprite.
  ///
  /// Effects are categorized by what they modify:
  /// - **Size effects**: Modify `sprite.size` (SVGPulse)
  /// - **Color effects**: Modify fill/stroke colors (SVGColorCycle, SVGStrokeCycle, SVGDualColorCycle)
  /// - **Vertex effects**: Modify vertex positions (SVGWobble, SVGExplode, SVGWave)
  ///
  /// Vertex effects are chained so each transformation builds on the previous.
  ///
  /// ### Usage:
  /// ```swift
  /// SVGSprite$()
  ///   .path("icon.svg")
  ///   .svgEffects {
  ///     SVGPulse(speed: 2.0, amplitude: 8.0)
  ///     SVGWobble(amount: state.wobbleAmount)
  ///     SVGColorCycle(speed: 0.5)
  ///   }
  /// ```
  func svgEffects(@SVGEffectBuilder _ builder: () -> [any SVGEffectProtocol]) -> Self {
    let effects = builder()
    let state = SVGEffectSharedState()

    return onProcess { sprite, delta in
      state.time += delta

      // Wait for sprite to be built before applying effects
      guard state.initializeIfNeeded(from: sprite) else { return }

      // Start with original vertices
      var currentVerts = state.originalVerts

      // Apply all effects, chaining vertex transformations
      for effect in effects {
        effect.update(delta: delta, state: state)
        currentVerts = effect.apply(sprite: sprite, state: state, currentVerts: currentVerts)
      }

      // Set final vertices
      for i in 0 ..< min(sprite.getElementCount(), currentVerts.count) {
        sprite.setVertices(PackedVector2Array(currentVerts[i]), forElement: i)
      }
    }
  }
}

// MARK: - Convenience Single-Effect Modifiers

/// These remain for simple single-effect use cases.
public extension GNode where T == SVGSprite {
  /// Pulses the sprite scale using a sine wave.
  /// - Parameters:
  ///   - speed: Oscillation speed (radians per second)
  ///   - amplitude: Scale variation (0.2 = ±20% size change)
  func pulse(speed: Double = 2.0, amplitude: Double = 0.2) -> Self {
    svgEffects { SVGPulse(speed: speed, amplitude: amplitude) }
  }

  /// Pulses the sprite scale using ObservableState binding.
  func pulse<O: AnyObject & Observable>(
    speed: ObservableProperty<O, Double>,
    amplitude: Double = 0.2
  ) -> Self {
    svgEffects { SVGPulse(speed: speed, amplitude: amplitude) }
  }

  /// Cycles the fill color through an array of colors.
  func colorCycle(_ colors: [Color], speed: Double = 0.5, elementIndex: Int = 0) -> Self {
    svgEffects { SVGColorCycle(colors, speed: speed, elementIndex: elementIndex) }
  }

  /// Cycles the stroke color through an array of colors.
  func strokeCycle(_ colors: [Color], speed: Double = 0.5, elementIndex: Int = 0) -> Self {
    svgEffects { SVGStrokeCycle(colors, speed: speed, elementIndex: elementIndex) }
  }

  /// Cycles both fill and stroke colors through separate color arrays.
  func dualColorCycle(
    fill fillColors: [Color],
    stroke strokeColors: [Color],
    fillSpeed: Double = 0.5,
    strokeSpeed: Double = 0.7,
    elementIndex: Int = 0
  ) -> Self {
    svgEffects {
      SVGDualColorCycle(
        fill: fillColors,
        stroke: strokeColors,
        fillSpeed: fillSpeed,
        strokeSpeed: strokeSpeed,
        elementIndex: elementIndex
      )
    }
  }

  /// Wobbles vertices radially from their center point.
  func wobble(amount: Double = 5.0, speed: Double = 4.0) -> Self {
    svgEffects { SVGWobble(amount: amount, speed: speed) }
  }

  /// Wobbles vertices with ObservableState binding.
  func wobble<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 4.0) -> Self {
    svgEffects { SVGWobble(amount: amount, speed: speed) }
  }

  /// Expands vertices outward from their center point.
  func explode(progress: Double, scale: Double = 50.0) -> Self {
    svgEffects { SVGExplode(progress: progress, scale: scale) }
  }

  /// Expands vertices with ObservableState binding.
  func explode<O: AnyObject & Observable>(progress: ObservableProperty<O, Double>, scale: Double = 50.0) -> Self {
    svgEffects { SVGExplode(progress: progress, scale: scale) }
  }

  /// Applies a horizontal wave deformation based on Y position.
  func wave(amplitude: Double = 3.0, frequency: Double = 0.2, speed: Double = 3.0) -> Self {
    svgEffects { SVGWave(amplitude: amplitude, frequency: frequency, speed: speed) }
  }

  /// Wave with ObservableState binding.
  func wave<O: AnyObject & Observable>(amplitude: ObservableProperty<O, Double>, frequency: Double = 0.2, speed: Double = 3.0) -> Self {
    svgEffects { SVGWave(amplitude: amplitude, frequency: frequency, speed: speed) }
  }

  // MARK: Game-Focused Effects

  /// Uniform breathing/pulsing expansion from center.
  func inflate(amount: Double = 5.0, speed: Double = 2.0) -> Self {
    svgEffects { SVGInflate(amount: amount, speed: speed) }
  }

  /// Inflate with ObservableState binding.
  func inflate<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 2.0) -> Self {
    svgEffects { SVGInflate(amount: amount, speed: speed) }
  }

  /// Shears/leans the shape based on Y position.
  func skew(amount: Double = 0.3, speed: Double = 2.0, animated: Bool = true) -> Self {
    svgEffects { SVGSkew(amount: amount, speed: speed, animated: animated) }
  }

  /// Skew with ObservableState binding.
  func skew<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 2.0, animated: Bool = true) -> Self {
    svgEffects { SVGSkew(amount: amount, speed: speed, animated: animated) }
  }

  /// Random per-vertex displacement for electric/glitch feel.
  func noise(amount: Double = 2.0, speed: Double = 10.0) -> Self {
    svgEffects { SVGNoise(amount: amount, speed: speed) }
  }

  /// Noise with ObservableState binding.
  func noise<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 10.0) -> Self {
    svgEffects { SVGNoise(amount: amount, speed: speed) }
  }

  /// Each path element drifts apart from global center.
  func scatter(progress: Double, scale: Double = 50.0, rotate: Bool = true) -> Self {
    svgEffects { SVGScatter(progress: progress, scale: scale, rotate: rotate) }
  }

  /// Scatter with ObservableState binding.
  func scatter<O: AnyObject & Observable>(progress: ObservableProperty<O, Double>, scale: Double = 50.0, rotate: Bool = true) -> Self {
    svgEffects { SVGScatter(progress: progress, scale: scale, rotate: rotate) }
  }

  /// Concentric waves emanating from center.
  func ripple(amplitude: Double = 3.0, frequency: Double = 0.3, speed: Double = 5.0) -> Self {
    svgEffects { SVGRipple(amplitude: amplitude, frequency: frequency, speed: speed) }
  }

  /// Ripple with ObservableState binding.
  func ripple<O: AnyObject & Observable>(amplitude: ObservableProperty<O, Double>, frequency: Double = 0.3, speed: Double = 5.0) -> Self {
    svgEffects { SVGRipple(amplitude: amplitude, frequency: frequency, speed: speed) }
  }

  /// Rotates vertices based on distance from center (spiral/vortex).
  func twist(amount: Double = 0.5, speed: Double = 2.0) -> Self {
    svgEffects { SVGTwist(amount: amount, speed: speed) }
  }

  /// Twist with ObservableState binding.
  func twist<O: AnyObject & Observable>(amount: ObservableProperty<O, Double>, speed: Double = 2.0) -> Self {
    svgEffects { SVGTwist(amount: amount, speed: speed) }
  }

}
