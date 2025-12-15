import SwiftGodot

// MARK: - TouchArea

/// Wraps content with an Area2D for detecting body/area interactions.
public struct TouchArea<Content: GView>: GView {
  let content: Content
  let collisionLayer: Physics2DLayer
  let collisionMask: Physics2DLayer
  let onBodyEntered: ((Node2D) -> Void)?
  let onBodyExited: ((Node2D) -> Void)?
  let onAreaEntered: ((Area2D) -> Void)?
  let onAreaExited: ((Area2D) -> Void)?

  public init(
    layer: Physics2DLayer = .alpha,
    mask: Physics2DLayer = .alpha,
    onBodyEntered: ((Node2D) -> Void)? = nil,
    onBodyExited: ((Node2D) -> Void)? = nil,
    onAreaEntered: ((Area2D) -> Void)? = nil,
    onAreaExited: ((Area2D) -> Void)? = nil,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    collisionLayer = layer
    collisionMask = mask
    self.onBodyEntered = onBodyEntered
    self.onBodyExited = onBodyExited
    self.onAreaEntered = onAreaEntered
    self.onAreaExited = onAreaExited
  }

  public var body: some GView {
    Area2D$ {
      content
    }
    .collisionLayer(collisionLayer)
    .collisionMask(collisionMask)
    .monitorable(true)
    .monitoring(true)
    .configure { area in
      if let onBodyEntered {
        area.bodyEntered.connect { body in
          guard let body else { return }
          onBodyEntered(body)
        }
      }
      if let onBodyExited {
        area.bodyExited.connect { body in
          guard let body else { return }
          onBodyExited(body)
        }
      }
      if let onAreaEntered {
        area.areaEntered.connect { other in
          guard let other else { return }
          onAreaEntered(other)
        }
      }
      if let onAreaExited {
        area.areaExited.connect { other in
          guard let other else { return }
          onAreaExited(other)
        }
      }
    }
  }
}

// MARK: - HitBox

/// A preconfigured Area2D for combat hit detection.
/// Typically used for attack hitboxes that detect hurtboxes.
public struct HitBox<Content: GView>: GView {
  let content: Content
  let layer: Physics2DLayer
  let mask: Physics2DLayer
  let onHit: (Area2D) -> Void

  @State var isActive = true

  public init(
    layer: Physics2DLayer = .none,
    mask: Physics2DLayer,
    active: State<Bool>? = nil,
    onHit: @escaping (Area2D) -> Void,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.layer = layer
    self.mask = mask
    self.onHit = onHit
    if let active {
      _isActive = active
    }
  }

  public var body: some GView {
    Area2D$ {
      content
    }
    .collisionLayer(layer)
    .collisionMask(mask)
    .monitorable(false)
    .monitoring($isActive)
    .onSignal(\.areaEntered) { _, area in
      guard let area else { return }
      onHit(area)
    }
  }
}

// MARK: - HurtBox

/// A preconfigured Area2D for receiving hits.
/// Typically placed on entities that can take damage.
public struct HurtBox<Content: GView>: GView {
  let content: Content
  let layer: Physics2DLayer
  let onHurt: (Area2D) -> Void

  @State var isActive = true

  public init(
    layer: Physics2DLayer,
    active: State<Bool>? = nil,
    onHurt: @escaping (Area2D) -> Void,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.layer = layer
    self.onHurt = onHurt
    if let active {
      _isActive = active
    }
  }

  public var body: some GView {
    Area2D$ {
      content
    }
    .collisionLayer(layer)
    .collisionMask(.none)
    .monitorable($isActive)
    .monitoring(false)
    .onSignal(\.areaEntered) { _, area in
      guard let area else { return }
      onHurt(area)
    }
  }
}

// MARK: - Pickup

/// An Area2D wrapper for collectible items.
public struct Pickup<Content: GView>: GView {
  let content: Content
  let layer: Physics2DLayer
  let mask: Physics2DLayer
  let autoRemove: Bool
  let onCollected: () -> Void

  public init(
    layer: Physics2DLayer = .alpha,
    mask: Physics2DLayer = .alpha,
    autoRemove: Bool = true,
    onCollected: @escaping () -> Void,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.layer = layer
    self.mask = mask
    self.autoRemove = autoRemove
    self.onCollected = onCollected
  }

  public var body: some GView {
    Area2D$ {
      content
    }
    .collisionLayer(layer)
    .collisionMask(mask)
    .monitorable(true)
    .monitoring(true)
    .onSignal(\.bodyEntered) { node, _ in
      onCollected()
      if autoRemove {
        node.queueFree()
      }
    }
  }
}
