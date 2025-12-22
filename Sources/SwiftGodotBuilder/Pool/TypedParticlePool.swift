import SwiftGodot

/// Multi-variant fire-and-forget pool for particles keyed by type.
///
/// Call `update(delta:)` each frame to process expirations.
public final class TypedParticlePool<Key: Hashable, T: Node2D> {
  /// Configuration for typed particle pool
  public struct Config {
    public var prewarmPerType: Int
    public var maxPerType: Int
    public var defaultLifetime: Double

    public init(prewarmPerType: Int = 5, maxPerType: Int = 50, defaultLifetime: Double = 1.0) {
      self.prewarmPerType = prewarmPerType
      self.maxPerType = maxPerType
      self.defaultLifetime = defaultLifetime
    }
  }

  /// Tracks a pending expiration
  private struct Expiration {
    let node: T
    let type: Key
    let expireAt: Double
  }

  public let config: Config

  private weak var parentNode: Node?
  private var pools: [Key: ObjectPool<T>] = [:]
  private var activeCount: [Key: Int] = [:]
  private let keys: [Key]
  private let factory: (Key) -> T

  // Expiration tracking
  private var expirations: [Expiration] = []
  private var currentTime: Double = 0

  // Cache lifetime per type (assumes all particles of same type have same lifetime)
  private var lifetimeCache: [Key: Double] = [:]

  /// Total number of active particles across all types
  public var totalActive: Int {
    activeCount.values.reduce(0, +)
  }

  /// Total number of available particles across all types
  public var totalAvailable: Int {
    pools.values.reduce(0) { $0 + $1.availableCount }
  }

  /// Active count for a specific type
  public func activeCount(for key: Key) -> Int {
    activeCount[key] ?? 0
  }

  public init(keys: [Key], config: Config = Config(), factory: @escaping (Key) -> T) {
    self.keys = keys
    self.config = config
    self.factory = factory

    // Initialize ObjectPool for each key
    for key in keys {
      let pool = ObjectPool<T>(factory: { factory(key) }, max: config.maxPerType)
      pool.keepInTree = true
      pools[key] = pool
      activeCount[key] = 0
    }
  }

  /// Sets up the pool with a parent node and prewarms particles
  public func setup(parent: Node) {
    parentNode = parent

    Engine.onNextFrame { [weak self, weak parent] in
      guard let self, let parent else { return }
      for key in keys {
        guard let pool = pools[key] else { continue }

        // Prewarm by acquiring and immediately releasing
        for _ in 0 ..< config.prewarmPerType {
          if let node = pool.acquire() {
            node.visible = false
            if node.getParent() == nil {
              parent.addChild(node: node)
            }

            // Cache lifetime from first node of each type
            if lifetimeCache[key] == nil {
              lifetimeCache[key] = getLifetime(for: node)
            }

            pool.release(node)
          }
        }
      }
    }
  }

  /// Updates expiration tracking. Call this every frame from onProcess.
  public func update(delta: Double) {
    currentTime += delta

    // Process expired particles (expirations are sorted by expireAt)
    while let first = expirations.first, first.expireAt <= currentTime {
      expirations.removeFirst()
      first.node.visible = false

      // Return to pool
      pools[first.type]?.release(first.node)
      activeCount[first.type, default: 1] -= 1
    }
  }

  deinit {
    // Clear pending expirations (nodes will be freed by their pools)
    expirations.removeAll()
    // ObjectPool deinits will handle freeing nodes when pools dict is released
    pools.removeAll()
  }

  /// Spawns a particle of the given type at position
  public func spawn(type: Key, at position: Vector2, scale: Vector2 = [1, 1]) {
    guard let parent = parentNode,
          let pool = pools[type],
          let node = pool.acquire() else { return }

    // Add to tree if needed (first time use after dynamic growth)
    if node.getParent() == nil {
      parent.addChild(node: node)

      // Cache lifetime if not already cached
      if lifetimeCache[type] == nil {
        lifetimeCache[type] = getLifetime(for: node)
      }
    }

    node.position = position
    node.scale = scale
    node.visible = true
    activateNode(node)
    activeCount[type, default: 0] += 1

    // Schedule expiration (insert sorted by expireAt)
    let lifetime = lifetimeCache[type] ?? config.defaultLifetime
    let expireAt = currentTime + lifetime
    insertExpiration(Expiration(node: node, type: type, expireAt: expireAt))
  }

  /// Insert expiration maintaining sorted order by expireAt
  private func insertExpiration(_ exp: Expiration) {
    // Most particles have similar lifetimes, so new expirations usually go near the end
    // Search from the end for efficiency
    var insertIndex = expirations.count
    while insertIndex > 0, expirations[insertIndex - 1].expireAt > exp.expireAt {
      insertIndex -= 1
    }
    expirations.insert(exp, at: insertIndex)
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
}
