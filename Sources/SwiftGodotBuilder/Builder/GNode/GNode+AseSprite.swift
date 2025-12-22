import Foundation
import SwiftGodot

// MARK: - Extension for GNode builder

public extension GNode where T == AseSprite {
  /// Convenience initializer for creating an `AseSprite` within a `GNode` builder context.
  ///
  /// ### Usage:
  /// ```swift
  /// AseSprite$(path: "hero", currentLayer: "sword")
  ///   .layer($weaponState) { $0 == .melee ? "sword" : "bow" }
  /// ```
  init(
    _ name: String? = UUID().uuidString,
    path: String,
    currentLayer: String = "",
    options: AseOptions = .init(),
    @NodeBuilder _ children: () -> [any GView] = { [] }
  ) {
    self.init(name, children, make: {
      let a = T()
      a.sourcePath = path
      a.currentLayer = currentLayer
      a.aseOptions = options
      return a
    })
  }

  /// Reactively set the current layer.
  /// This does NOT reload - just changes which layer's animations play via `playAnimation()`.
  ///
  /// ### Usage:
  /// ```swift
  /// AseSprite$(path: "hero", currentLayer: "sword")
  ///   .layer($weaponLayer)
  /// ```
  func layer(_ state: GState<String>) -> Self {
    watch(state) { sprite, layer in
      sprite.currentLayer = layer
    }
  }

  /// Reactively set the current layer with a transform.
  func layer<V>(_ state: GState<V>, _ transform: @escaping (V) -> String) -> Self {
    watch(state) { sprite, value in
      sprite.currentLayer = transform(value)
    }
  }

  /// Stop animation playback after ready (shows first frame only).
  /// Useful for static icon display in UI.
  func paused() -> Self {
    onReady { sprite in
      Engine.onNextFrame {
        sprite.stop()
      }
    }
  }
}

public typealias AseSprite$ = GNode<AseSprite>
