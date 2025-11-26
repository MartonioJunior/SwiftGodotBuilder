import SwiftGodot

// MARK: - Color Extensions

public extension Color {
  /// Returns a new Color with the specified alpha value.
  ///
  /// - Parameter alpha: The alpha value (0.0 to 1.0)
  /// - Returns: A new Color with the same RGB values but different alpha
  func withAlpha(_ alpha: Double) -> Color {
    Color(r: self.red, g: self.green, b: self.blue, a: Float(alpha))
  }
}

// This is safe because Floats are Sendable
extension Color: @retroactive @unchecked Sendable {
  public func toSendable() -> (Float, Float, Float, Float) { (red, green, blue, alpha) }
  public static func fromSendable(_ value: (Float, Float, Float, Float)) -> Color {
    Color(r: value.0, g: value.1, b: value.2, a: value.3)
  }
}
