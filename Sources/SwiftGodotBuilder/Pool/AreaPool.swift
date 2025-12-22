import SwiftGodot

/// Manages a pool of Area2D nodes with velocity-based movement.
/// Useful for projectiles, bullets, or any moving Area2D objects.
///
/// The factory closure should define the Area2D with any game-specific
/// signal handlers (e.g., `.onSignal(\.areaEntered)` for collision events).
/// AreaPool handles the pooling mechanics internally.
public final class AreaPool {
  public struct ActiveArea {
    public var node: Area2D
    public var velocity: Vector2
    public var age: Double = 0
  }

  private let pool: ObjectPool<Area2D>
  private var active: [ActiveArea] = []
  private let preloadCount: Int
  private let makeArea: () -> GNode<Area2D>

  // O(1) lookup: node ObjectIdentifier -> index in active array
  private var nodeToIndex: [ObjectIdentifier: Int] = [:]

  public let speed: Float
  public let lifetime: Double
  public let bounds: (minX: Float, maxX: Float, minY: Float, maxY: Float)

  public init(
    preload: Int = 30,
    maxSize: Int = 30,
    speed: Float = 300,
    lifetime: Double = 3.0,
    bounds: (minX: Float, maxX: Float, minY: Float, maxY: Float) = (-50, 850, -50, 290),
    factory: @escaping () -> GNode<Area2D>
  ) {
    pool = ObjectPool<Area2D>(max: maxSize)
    self.speed = speed
    self.lifetime = lifetime
    self.bounds = bounds
    preloadCount = preload
    makeArea = factory

    pool.factory = { [weak self] in
      guard let self else { return Area2D() }
      let area = self.makeArea()
        .visible(false)
        .monitorable(false)
        .monitoring(false)
        .toNode() as! Area2D
      return self.wrapWithCollisionHandlers(area)
    }
  }

  private weak var parentNode: Node?

  deinit {
    for activeArea in active {
      activeArea.node.queueFree()
    }
    active.removeAll()
  }

  /// Call this once the pool's parent node is in the scene tree.
  /// Preloads nodes and adds them to the parent so they stay in tree.
  public func start(parent: Node) {
    parentNode = parent
    Engine.onNextFrame { [weak self, weak parent] in
      guard let self, let parent else { return }
      // Preload and immediately add all nodes to scene tree
      for _ in 0 ..< preloadCount {
        if let node = pool.acquire() {
          if node.getParent() == nil {
            parent.addChild(node: node)
          }
          pool.release(node)
        }
      }
    }
  }

  public func fire(at position: Vector2, direction: Vector2, parent: Node) {
    guard let node = pool.acquire() else { return }

    let normalizedDir = direction.normalized()
    node.position = position
    node.scale.x = direction.x < 0 ? -1 : 1
    node.visible = true
    node.monitorable = true
    node.monitoring = true

    // Only add to tree if not already parented
    if node.getParent() == nil {
      parent.addChild(node: node)
    }

    // Track index for O(1) collision lookup
    let index = active.count
    nodeToIndex[ObjectIdentifier(node)] = index

    active.append(ActiveArea(
      node: node,
      velocity: normalizedDir * speed
    ))
  }

  public func update(delta: Double) {
    // Update positions and collect expired projectiles
    // Iterate backwards so we can swap-remove in place
    var i = active.count - 1
    while i >= 0 {
      active[i].age += delta
      active[i].node.position += active[i].velocity * Float(delta)

      let pos = active[i].node.position

      if active[i].age > lifetime ||
        pos.x < bounds.minX || pos.x > bounds.maxX ||
        pos.y < bounds.minY || pos.y > bounds.maxY
      {
        returnToPoolSwap(index: i)
      }
      i -= 1
    }
  }

  private func wrapWithCollisionHandlers(_ area: Area2D) -> Area2D {
    _ = area.bodyEntered.connect { [weak self, weak area] _ in
      guard let self, let area else { return }
      self.handleCollision(node: area)
    }

    _ = area.areaEntered.connect { [weak self, weak area] _ in
      guard let self, let area else { return }
      self.handleCollision(node: area)
    }

    return area
  }

  private func handleCollision(node: Area2D) {
    // O(1) lookup via dictionary
    let nodeId = ObjectIdentifier(node)
    guard let index = nodeToIndex[nodeId] else { return }
    returnToPoolSwap(index: index)
  }

  /// O(1) swap-and-pop removal
  private func returnToPoolSwap(index: Int) {
    let projectile = active[index]
    let node = projectile.node
    let nodeId = ObjectIdentifier(node)

    // Remove from index tracking
    nodeToIndex.removeValue(forKey: nodeId)

    // Swap with last element for O(1) removal
    let lastIndex = active.count - 1
    if index != lastIndex {
      active[index] = active[lastIndex]
      // Update the swapped element's index in the dictionary
      nodeToIndex[ObjectIdentifier(active[index].node)] = index
    }
    active.removeLast()

    // Immediately hide to prevent visual glitches
    node.visible = false
    node.position = [-9999, -9999]

    // Defer physics changes to avoid modifying state during callbacks
    Engine.onNextFrame { [weak self] in
      node.monitorable = false
      node.monitoring = false
      self?.pool.release(node)
    }
  }
}
