import Foundation
import SwiftGodot

/// A declarative view that loads and renders an LDtk level.
///
/// ### Basic Usage:
/// ```swift
/// LDLevelView(project, level: "Level_0")
/// ```
///
/// ### With Configuration:
/// ```swift
/// LDLevelView(project, level: "Level_0")
///   .generateCollision(values: [1, 2])
///   .zIndexOffset(10)
/// ```
///
/// ### With Entity Handlers:
/// ```swift
/// LDLevelView(project, level: "Level_0")
///   .onEntitySpawn("Player") { entity, level, project in
///     CharacterBody2D$ {
///       Sprite2D$().res(\.texture, "player.png")
///     }
///     .position(entity.positionCenter)
///   }
///   .onEntity("PlayerSpawn") { entity, _, _ in
///     // Side effects only, no node spawned
///     spawnPosition = entity.position
///   }
/// ```
public struct LDLevelView: GView {
  /// Pre-loaded project instance
  private let project: LDProject

  /// Reactive level identifier source (all inits populate this)
  private let levelSource: any ReactiveSource<String>

  /// Build configuration
  private var config: LDLevelBuildConfig

  /// Entity mappers (registered for this level)
  private var mappers: [String: LDEntityMapper] = [:]

  /// Initialize with a pre-loaded project and static level identifier
  /// - Parameters:
  ///   - project: Pre-loaded LDProject (must have been loaded via LDProject.load())
  ///   - level: Level identifier to build
  public init(_ project: LDProject, level levelIdentifier: String) {
    self.project = project
    levelSource = GState(wrappedValue: levelIdentifier)
    config = LDLevelBuildConfig()
  }

  /// Initialize with a pre-loaded project and reactive level identifier
  ///
  /// When the level identifier changes, the view automatically rebuilds with the new level.
  ///
  /// ### Usage:
  /// ```swift
  /// LDLevelView(project, level: $state.currentLevelId)
  ///   .onEntitySpawn("Player") { entity, level, project in
  ///     PlayerView(entity: entity)
  ///   }
  /// ```
  ///
  /// - Parameters:
  ///   - project: Pre-loaded LDProject (must have been loaded via LDProject.load())
  ///   - level: Reactive source for the level identifier
  public init(_ project: LDProject, level: some ReactiveSource<String>) {
    self.project = project
    levelSource = level
    config = LDLevelBuildConfig()
  }

  public func toNode() -> Node {
    buildReactiveNode(levelSource: levelSource)
  }

  /// Builds a container node that reactively rebuilds when the level changes
  private func buildReactiveNode(levelSource: any ReactiveSource<String>) -> Node {
    let container = Node2D()
    container.name = "LDLevelContainer"

    // Capture self's configuration for use in the observer
    let project = self.project
    let config = self.config
    let mappers = self.mappers

    levelSource.observe { [weak container] levelId in
      guard let container else { return }

      // Remove old level
      for child in container.getChildren() {
        child?.queueFree()
      }

      // Skip empty level IDs
      guard !levelId.isEmpty else { return }

      // Build the new level
      let levelNode = Self.buildLevel(
        project: project,
        identifier: levelId,
        config: config,
        mappers: mappers
      )

      // Add to container (use onNextFrame to avoid "Parent node is busy" errors)
      Engine.onNextFrame {
        container.addChild(node: levelNode)
      }
    }

    return container
  }

  /// Static helper to build a level with the given configuration
  private static func buildLevel(
    project: LDProject,
    identifier: String,
    config: LDLevelBuildConfig,
    mappers: [String: LDEntityMapper]
  ) -> Node {
    let levelBuilder = LDLevelBuilder(project: project)

    // Register mappers
    for (_, mapper) in mappers {
      config.entityConfig.registry.register(mapper)
    }

    // Build the level
    guard let levelNode = levelBuilder.buildLevel(identifier: identifier, config: config) else {
      GD.printErr("Failed to build LDtk level: \(identifier)")
      return Node2D()
    }

    return levelNode
  }

  // MARK: - Configuration Modifiers

  /// Explicitly enable or disable entity spawning.
  /// Note: Entity spawning is enabled by default. Use `.spawnEntities(false)` to disable.
  public func spawnEntities(_ enabled: Bool = true) -> Self {
    var view = self
    view.config.spawnEntities = enabled
    return view
  }

  /// Set z-index offset for layers.
  public func zIndexOffset(_ offset: Int32) -> Self {
    var view = self
    view.config.zIndexOffset = offset
    return view
  }

  /// Create marker nodes for unmapped entities.
  public func createEntityMarkers(_ enabled: Bool = true) -> Self {
    var view = self
    view.config.entityConfig.createMarkersForUnmapped = enabled
    return view
  }

  /// Set entity z-index offset.
  public func entityZIndexOffset(_ offset: Int32) -> Self {
    var view = self
    view.config.entityConfig.zIndexOffset = offset
    return view
  }

  /// Add an entity filter to control which entities are spawned.
  public func entityFilter(_ filter: @escaping (LDEntity) -> Bool) -> Self {
    var view = self
    view.config.entityConfig.entityFilter = filter
    return view
  }

  /// Add a post-processor for spawned entity nodes.
  public func onSpawned(_ processor: @escaping (LDEntity, Node2D) -> Void) -> Self {
    var view = self
    view.config.entityConfig.onSpawned = processor
    return view
  }

  /// Add custom layer processor.
  public func onLayer(_ processor: @escaping (LDLayer) -> Node?) -> Self {
    var view = self
    view.config.onLayer = processor
    return view
  }

  // MARK: - Entity Handlers

  /// Spawn a node for an entity using a GView builder.
  /// - Parameters:
  ///   - identifier: Entity identifier to handle
  ///   - builder: Closure that creates a GView for the entity
  public func onEntitySpawn(_ identifier: String, builder: @escaping (LDEntity, LDLevel, LDProject) -> any GView) -> Self {
    var view = self
    let capturedProject = project

    let mapper = LDClosureEntityMapper(identifier: identifier) { entity, level in
      let gView = builder(entity, level, capturedProject)
      let node = gView.toNode()

      guard let node2D = node as? Node2D else {
        GD.printErr("Entity mapper for '\(identifier)' must return a Node2D")
        return nil
      }

      return node2D
    }

    view.mappers[identifier] = mapper
    return view
  }

  /// Spawn a node for an entity using a Node2D builder.
  /// Return nil to skip spawning.
  /// - Parameters:
  ///   - identifier: Entity identifier to handle
  ///   - builder: Closure that creates a Node2D (or nil)
  public func onEntitySpawn(_ identifier: String, builder: @escaping (LDEntity, LDLevel, LDProject) -> Node2D?) -> Self {
    var view = self
    let capturedProject = project

    let mapper = LDClosureEntityMapper(identifier: identifier) { entity, level in
      builder(entity, level, capturedProject)
    }

    view.mappers[identifier] = mapper
    return view
  }

  /// Handle an entity for side effects without spawning a node.
  /// Use for marker entities like spawn points that only provide position data.
  /// - Parameters:
  ///   - identifier: Entity identifier to handle
  ///   - handler: Closure that processes the entity data
  public func onEntity(_ identifier: String, handler: @escaping (LDEntity, LDLevel, LDProject) -> Void) -> Self {
    var view = self
    let capturedProject = project

    let mapper = LDClosureEntityMapper(identifier: identifier) { entity, level in
      handler(entity, level, capturedProject)
      return nil
    }

    view.mappers[identifier] = mapper
    return view
  }
}
