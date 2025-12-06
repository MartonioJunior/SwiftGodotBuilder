import Foundation
import SwiftGodot

// MARK: - Entity Build Configuration

/// Configuration for entity building
public struct LDEntityBuildConfig {
  /// The mapper registry to use (defaults to shared)
  public var registry: LDEntityMapperRegistry = .shared

  /// Optional post-processor - called after node creation
  public var onSpawned: ((LDEntity, Node2D) -> Void)?

  public init() {}
}

// MARK: - Entity Builder

/// Builds Godot nodes from LDtk entity instances
public class LDEntityBuilder {
  /// Reference to the project for definitions
  private let project: LDProject

  public init(project: LDProject) {
    self.project = project
  }

  /// Build entity nodes from a layer instance
  /// - Parameters:
  ///   - layer: The entity layer instance
  ///   - level: The level containing this layer
  ///   - config: Build configuration
  /// - Returns: Node2D container with all spawned entities
  public func buildEntityLayer(
    from layer: LDLayer,
    level: LDLevel,
    config: LDEntityBuildConfig = LDEntityBuildConfig(),
  ) -> Node2D? {
    guard layer.type == .entities else {
      GD.printErr("Layer \(layer.identifier) is not an entity layer")
      return nil
    }

    // Create container node
    let container = Node2D()
    container.name = StringName(layer.identifier)
    container.position = layer.totalOffset

    for entity in layer.entityInstances.reversed() {
      if let entityNode = spawnEntity(entity, level: level, config: config) {
        container.addChild(node: entityNode)
      }
    }

    return container
  }

  /// Build all entity layers from a level
  /// - Parameters:
  ///   - level: The level to process
  ///   - config: Build configuration
  /// - Returns: Array of entity layer container nodes
  public func buildAllEntityLayers(
    from level: LDLevel,
    config: LDEntityBuildConfig = LDEntityBuildConfig()
  ) -> [Node2D] {
    guard let layers = level.layerInstances else {
      return []
    }

    var result: [Node2D] = []

    for layer in layers where layer.type == .entities {
      if let entityLayer = buildEntityLayer(from: layer, level: level, config: config) {
        result.append(entityLayer)
      }
    }

    return result
  }

  /// Spawn a single entity
  /// - Parameters:
  ///   - entity: The entity instance to spawn
  ///   - level: The level containing this entity
  ///   - config: Build configuration
  /// - Returns: The spawned node, or nil if not spawned
  public func spawnEntity(
    _ entity: LDEntity,
    level: LDLevel,
    config: LDEntityBuildConfig = LDEntityBuildConfig()
  ) -> Node2D? {
    // Try to get a mapper from the registry
    guard let mapper = config.registry.mapper(for: entity.identifier) else {
      return nil
    }

    // Create the node
    guard let node = mapper.createNode(from: entity, level: level) else {
      return nil
    }

    // Apply post-processor if configured
    config.onSpawned?(entity, node)

    return node
  }

  /// Spawn multiple entities
  /// - Parameters:
  ///   - entities: Array of entity instances
  ///   - level: The level containing these entities
  ///   - config: Build configuration
  /// - Returns: Array of spawned nodes
  public func spawnEntities(
    _ entities: [LDEntity],
    level: LDLevel,
    config: LDEntityBuildConfig = LDEntityBuildConfig()
  ) -> [Node2D] {
    return entities.compactMap { spawnEntity($0, level: level, config: config) }
  }
}
