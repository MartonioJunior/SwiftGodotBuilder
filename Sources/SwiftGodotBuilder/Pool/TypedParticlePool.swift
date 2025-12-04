import SwiftGodot

/// Multi-variant fire-and-forget pool for particles keyed by type
public final class TypedParticlePool<Key: Hashable, T: Node2D> {
  /// Configuration for typed particle pool
  public struct Config {
    public var prewarmPerType: Int
    public var defaultLifetime: Double

    public init(prewarmPerType: Int = 5, defaultLifetime: Double = 1.0) {
      self.prewarmPerType = prewarmPerType
      self.defaultLifetime = defaultLifetime
    }
  }

  public let config: Config

  private weak var parentNode: Node?
  private var pools: [Key: [T]] = [:]
  private var activeCount: [Key: Int] = [:]
  private let keys: [Key]
  private let factory: (Key) -> T

  /// Total number of active particles across all types
  public var totalActive: Int {
    activeCount.values.reduce(0, +)
  }

  /// Total number of available particles across all types
  public var totalAvailable: Int {
    pools.values.reduce(0) { total, pool in
      total + pool.filter { !isNodeActive($0) }.count
    }
  }

  /// Active count for a specific type
  public func activeCount(for key: Key) -> Int {
    activeCount[key] ?? 0
  }

  public init(keys: [Key], config: Config = Config(), factory: @escaping (Key) -> T) {
    self.keys = keys
    self.config = config
    self.factory = factory

    // Initialize pools for each key
    for key in keys {
      pools[key] = []
      activeCount[key] = 0
    }
  }

  /// Sets up the pool with a parent node
  public func setup(parent: Node) {
    parentNode = parent

    Engine.onNextFrame { [weak self, weak parent] in
      guard let self, let parent else { return }
      for key in keys {
        for _ in 0 ..< config.prewarmPerType {
          let node = factory(key)
          node.visible = false
          parent.addChild(node: node)
          pools[key]?.append(node)
        }
      }
    }
  }

  /// Spawns a particle of the given type at position
  public func spawn(type: Key, at position: Vector2) {
    guard let parent = parentNode else { return }

    // Find an available particle or create new
    var node: T?

    if let pool = pools[type] {
      node = pool.first { !isNodeActive($0) }
    }

    if node == nil {
      // Create new particle if pool exhausted (dynamic growth)
      let newNode = factory(type)
      parent.addChild(node: newNode)
      pools[type]?.append(newNode)
      node = newNode
    }

    guard let n = node else { return }

    n.position = position
    n.visible = true
    activateNode(n)
    activeCount[type, default: 0] += 1

    // Schedule return to pool after lifetime
    scheduleDeactivation(node: n, type: type, lifetime: getLifetime(for: n))
  }

  /// Check if a node is currently active
  private func isNodeActive(_ node: T) -> Bool {
    // For CPUParticles2D, check emitting state
    if let particles = node as? CPUParticles2D {
      return particles.emitting || particles.visible
    }
    // For other nodes, just check visibility
    return node.visible
  }

  /// Activate a node for emission
  private func activateNode(_ node: T) {
    if let particles = node as? CPUParticles2D {
      particles.emitting = true
    }
  }

  /// Get lifetime for a node
  private func getLifetime(for node: T) -> Double {
    if let particles = node as? CPUParticles2D {
      return particles.lifetime + 0.1 // Small buffer for safety
    }
    return config.defaultLifetime
  }

  /// Schedule deactivation after lifetime
  private func scheduleDeactivation(node: T, type: Key, lifetime: Double) {
    guard let tree = Engine.getSceneTree(),
          let timer = tree.createTimer(timeSec: lifetime)
    else { return }

    _ = timer.timeout.connect { [weak self, weak node] in
      guard let node else { return }
      node.visible = false
      self?.activeCount[type, default: 1] -= 1
    }
  }
}
