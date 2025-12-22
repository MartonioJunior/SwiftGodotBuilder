import SwiftGodot

/// A pool for reusing Actor nodes of a single type.
///
/// Each pool manages actors of one type (e.g., slimes, bats). Create one pool per actor type
/// for optimal reuse. The pool handles node lifecycle and state reset automatically.
///
/// ### Example
/// ```swift
/// let slimePool = ActorPool(
///   prewarm: 10,
///   max: 50,
///   make: {
///     let state = ActorState()
///     let node = SlimeActor(state: state).toNode() as! CharacterBody2D
///     return (node, state)
///   },
///   makeBehavior: { AnyBehaviorMachine(SlimeBehavior()) }
/// )
///
/// slimePool.setup(parent: levelNode)
///
/// // Spawn
/// slimePool.spawn(at: spawnPoint)
///
/// // Release (typically via ActorEvent.died listener)
/// slimePool.release(actorId: deadActorId)
/// ```
public final class ActorPool {
  // MARK: - Configuration

  private let prewarm: Int
  private let pool: ObjectPool<CharacterBody2D>
  private let makeFn: () -> (CharacterBody2D, ActorState)
  private let makeBehaviorFn: (() -> AnyBehaviorMachine)?

  // MARK: - State Tracking

  /// Maps node identity to its ActorState
  private var stateByNode: [ObjectIdentifier: ActorState] = [:]

  /// Maps actor ID to its ActorState (for release by ID)
  private var stateById: [Int: ActorState] = [:]

  /// Parent node for spawned actors
  private weak var parent: Node?

  // MARK: - Initialization

  /// Creates a new actor pool.
  /// - Parameters:
  ///   - prewarm: Number of actors to pre-create during setup (default: 5)
  ///   - max: Maximum pool size (default: 50)
  ///   - make: Closure that creates a new actor node and its state
  ///   - makeBehavior: Optional closure to create fresh behavior machine on spawn
  public init(
    prewarm: Int = 5,
    max: Int = 50,
    make: @escaping () -> (CharacterBody2D, ActorState),
    makeBehavior: (() -> AnyBehaviorMachine)? = nil
  ) {
    self.prewarm = prewarm
    makeFn = make
    makeBehaviorFn = makeBehavior

    // Create the underlying pool with weak self to avoid retain cycle
    pool = ObjectPool<CharacterBody2D>(max: max)
    pool.factory = { [weak self] in
      let (node, state) = make()
      state.isPooled = true
      let nodeId = ObjectIdentifier(node)
      self?.stateByNode[nodeId] = state

      // Clean up stateByNode when node is actually freed (not just released to pool).
      // treeExiting fires both when removed for pooling AND when freed via queueFree.
      // We only want to clear callbacks when actually freed.
      _ = node.treeExiting.connect { [weak self] in
        guard let self else { return }
        // Only clean up if node is being freed, not just removed for pooling
        guard node.isQueuedForDeletion() else { return }

        if let removedState = self.stateByNode.removeValue(forKey: nodeId) {
          // Also remove from stateById if still tracked
          self.stateById.removeValue(forKey: removedState.id)
          // Clear callbacks to release any captured references
          removedState.clearCallbacks()
        }
      }

      return node
    }

    // keepInTree = false removes actors from tree on release, which:
    // 1. Triggers _exitTree on GEventRelay to cancel subscriptions
    // 2. GEventRelay._enterTree re-subscribes when actor is re-spawned
    pool.keepInTree = false
  }

  deinit {
    // Clear state tracking (nodes freed by ObjectPool's deinit)
    stateByNode.removeAll()
    stateById.removeAll()
  }

  // MARK: - Setup

  /// Sets up the pool with a parent node and pre-warms instances.
  /// - Parameter parent: The parent node where spawned actors will be added
  public func setup(parent: Node) {
    self.parent = parent
    pool.preload(prewarm)
  }

  // MARK: - Spawn

  /// Spawns an actor at the given position.
  /// - Parameters:
  ///   - position: World position for the actor
  ///   - facing: Initial facing direction (default: .right)
  /// - Returns: The spawned node, or nil if pool is exhausted
  @discardableResult
  public func spawn(at position: Vector2, facing: Facing = .right) -> CharacterBody2D? {
    guard let node = pool.acquire() else { return nil }

    // Get state for this node
    let nodeId = ObjectIdentifier(node)
    let state: ActorState
    if let existing = stateByNode[nodeId] {
      state = existing
      // Remove old ID mapping before reset generates new ID
      stateById.removeValue(forKey: state.id)
    } else {
      // Node was created outside our make (shouldn't happen, but handle it)
      let (_, newState) = makeFn()
      newState.isPooled = true
      stateByNode[nodeId] = newState
      state = newState
    }

    // Reset state for fresh use
    state.reset(facing: facing)
    state.node = node

    // Assign behavior machine if makeBehavior provided
    if let mb = makeBehaviorFn {
      state.behaviorMachine = mb()
    }

    // Track by actor ID
    stateById[state.id] = state

    // Configure node
    node.position = position
    node.visible = true
    node.setPhysicsProcess(enable: true)
    node.setProcess(enable: true)

    // Add to tree if needed
    if node.getParent() == nil, let p = parent {
      p.addChild(node: node)
    }

    return node
  }

  // MARK: - Release

  /// Releases an actor back to the pool by its actor ID.
  /// - Parameter actorId: The actor's state ID
  /// - Returns: True if the actor was found and released
  @discardableResult
  public func release(actorId: Int) -> Bool {
    guard let state = stateById.removeValue(forKey: actorId),
          let node = state.node else { return false }

    // Note: callbacks are NOT cleared here - they persist across pool cycles
    // just like GEventRelay subscriptions. Callbacks are only cleared when
    // the node is actually freed (via treeExiting signal in factory).

    // Hide and disable
    node.visible = false
    node.setPhysicsProcess(enable: false)
    node.setProcess(enable: false)

    // Return to pool
    pool.release(node)

    return true
  }

  /// Releases an actor back to the pool by node reference.
  /// - Parameter node: The actor's CharacterBody2D node
  /// - Returns: True if the actor was found and released
  @discardableResult
  public func release(node: CharacterBody2D) -> Bool {
    let nodeId = ObjectIdentifier(node)
    guard let state = stateByNode[nodeId] else { return false }

    // Remove from ID tracking
    stateById.removeValue(forKey: state.id)

    // Note: callbacks are NOT cleared here - they persist across pool cycles
    // just like GEventRelay subscriptions. Callbacks are only cleared when
    // the node is actually freed (via treeExiting signal in factory).

    // Hide and disable
    node.visible = false
    node.setPhysicsProcess(enable: false)
    node.setProcess(enable: false)

    // Return to pool
    pool.release(node)

    return true
  }

  // MARK: - Queries

  /// Number of actors currently available in the pool
  public var availableCount: Int {
    pool.availableCount
  }

  /// Number of actors currently spawned (active)
  public var activeCount: Int {
    stateById.count
  }

  /// Gets the ActorState for a spawned actor by ID
  public func state(for actorId: Int) -> ActorState? {
    stateById[actorId]
  }
}
