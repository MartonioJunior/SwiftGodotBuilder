import Foundation
import SwiftGodot

// MARK: - Extension for GNode builder

public extension GNode where T == AseSprite {
  /// Convenience initializer for creating an `AseSprite` within a `GNode` builder context.
  ///
  /// ### Usage:
  /// ```swift
  /// AseSprite$(path: "DinoSprites", layer: "MORT")
  ///   .onReady { sprite in sprite.play(name: "Walk") }
  /// ```
  init(
    _ name: String? = UUID().uuidString,
    path: String,
    layer: String? = nil,
    options: AseOptions = .init(),
    @NodeBuilder _ children: () -> [any GView] = { [] }
  ) {
    self.init(name, children, make: {
      let a = T()
      a.sourcePath = path
      a.layerName = layer
      a.aseOptions = options
      return a
    })
  }
}

public typealias AseSprite$ = GNode<AseSprite>
