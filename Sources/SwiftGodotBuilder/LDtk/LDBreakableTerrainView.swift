import SwiftGodot

/// A tile layer where tiles can be destroyed by collision interactions.
///
/// When a tile's detection area is triggered, the tile is removed from the TileMapLayer
/// and its collision is disabled.
///
/// ### Basic Usage:
/// ```swift
/// LDBreakableTerrainView(layer: breakableLayer, project: project)
///   .terrainCollisionLayer(.terrain)
///   .detectionMask(.combat)
///   .onTileDestroyed { position in
///     GameEvent.terrainDestroyed(position: position).emit()
///   }
/// ```
public struct LDBreakableTerrainView: GView {
  let layer: LDLayer
  let project: LDProject

  private var terrainLayer: UInt32 = 1
  private var detectionLayer: UInt32 = 0
  private var detectionMask: UInt32 = 1
  private var onDestroyedHandler: ((Vector2) -> Void)?
  private var onResetHandler: (() -> Void)?

  /// Initialize with a tile layer.
  /// - Parameters:
  ///   - layer: The tile layer to make breakable
  ///   - project: The LDtk project (for tileset building)
  public init(layer: LDLayer, project: LDProject) {
    self.layer = layer
    self.project = project
  }

  public func toNode() -> Node {
    BreakableTerrainNode(
      layer: layer,
      project: project,
      terrainLayer: terrainLayer,
      detectionLayer: detectionLayer,
      detectionMask: detectionMask,
      onDestroyed: onDestroyedHandler,
      onReset: onResetHandler
    ).toNode()
  }

  // MARK: - Configuration

  /// Set the collision layer for terrain bodies.
  public func terrainCollisionLayer(_ layer: UInt32) -> Self {
    var view = self
    view.terrainLayer = layer
    return view
  }

  /// Set the collision layer for detection areas.
  public func detectionLayer(_ layer: UInt32) -> Self {
    var view = self
    view.detectionLayer = layer
    return view
  }

  /// Set the collision mask for detection areas.
  public func detectionMask(_ mask: UInt32) -> Self {
    var view = self
    view.detectionMask = mask
    return view
  }

  /// Handle when a tile is destroyed.
  /// - Parameter handler: Closure called with the world position of the destroyed tile's center
  public func onTileDestroyed(_ handler: @escaping (Vector2) -> Void) -> Self {
    var view = self
    view.onDestroyedHandler = handler
    return view
  }

  /// Handle reset events (for game restart).
  /// - Parameter handler: Closure called when tiles should reset
  public func onReset(_ handler: @escaping () -> Void) -> Self {
    var view = self
    view.onResetHandler = handler
    return view
  }
}

// MARK: - Internal Implementation

private struct BreakableTerrainNode: GView {
  let layer: LDLayer
  let project: LDProject
  let terrainLayer: UInt32
  let detectionLayer: UInt32
  let detectionMask: UInt32
  let onDestroyed: ((Vector2) -> Void)?
  let onReset: (() -> Void)?

  @State var aliveTiles: Set<String> = []
  @State var tileMapRef: TileMapLayer? = nil
  @State var collisionBodies: [String: StaticBody2D] = [:]

  var gridSize: Int { layer.gridSize }
  var layerOffset: Vector2 { layer.totalOffset }

  var body: some GView {
    Node2D$()
      .position(layerOffset)
      .onReady { node in
        // Initialize alive tiles set
        var tiles = Set<String>()
        for tile in layer.allTiles {
          let gridX = tile.px[0] / gridSize
          let gridY = tile.px[1] / gridSize
          tiles.insert("\(gridX)_\(gridY)")
        }
        aliveTiles = tiles

        // Defer adding children to next frame
        Engine.onNextFrame {
          // Build and add the TileMapLayer
          if let tileMap = buildTileMapLayer() {
            tileMapRef = tileMap
            node.addChild(node: tileMap)
          }

          // Create hit detection areas and collision bodies for each tile
          for tile in layer.allTiles {
            let gridX = tile.px[0] / gridSize
            let gridY = tile.px[1] / gridSize
            let key = "\(gridX)_\(gridY)"
            let tileCenter: Vector2 = [
              Float(tile.px[0]) + Float(gridSize) / 2,
              Float(tile.px[1]) + Float(gridSize) / 2,
            ]

            // Detection area (Area2D)
            let areaNode = Area2D$ {
              CollisionShape2D$()
                .shape(RectangleShape2D(w: Float(gridSize), h: Float(gridSize)))
            }
            .position(tileCenter)
            .collisionLayer(detectionLayer)
            .collisionMask(detectionMask)
            .onSignal(\.areaEntered) { areaRef, _ in
              destroyTile(gridX: gridX, gridY: gridY, node: areaRef)
            }
            .toNode()

            node.addChild(node: areaNode)

            // Terrain collision (StaticBody2D)
            let collisionBody = StaticBody2D$ {
              CollisionShape2D$()
                .shape(RectangleShape2D(w: Float(gridSize), h: Float(gridSize)))
                .position([Float(gridSize) / 2, Float(gridSize) / 2])
            }
            .position([Float(tile.px[0]), Float(tile.px[1])])
            .collisionLayer(terrainLayer)
            .collisionMask(0)
            .toNode() as! StaticBody2D

            node.addChild(node: collisionBody)
            collisionBodies[key] = collisionBody
          }
        }
      }
  }

  func buildTileMapLayer() -> TileMapLayer? {
    guard let projectPath = project.projectPath else {
      GD.printErr("LDBreakableTerrainView: Project must have projectPath set")
      return nil
    }

    let tilesetBuilder = LDTileSetBuilder(projectPath: projectPath)
    let tileMapBuilder = LDTileMapBuilder(project: project, tilesetBuilder: tilesetBuilder)

    if let result = tileMapBuilder.buildTileMapLayer(from: layer) {
      // buildTileMapLayer can return Node2D (container) or TileMapLayer
      if let tileMap = result as? TileMapLayer {
        return tileMap
      }
      // If it's a container with stacked layers, get the first TileMapLayer
      for i in 0 ..< result.getChildCount() {
        if let tileMap = result.getChild(idx: i) as? TileMapLayer {
          return tileMap
        }
      }
    }

    if !layer.allTiles.isEmpty {
      GD.printErr("LDBreakableTerrainView: Failed to build TileMapLayer for '\(layer.identifier)'")
    }

    return nil
  }

  func destroyTile(gridX: Int, gridY: Int, node: Node) {
    let key = "\(gridX)_\(gridY)"
    guard aliveTiles.contains(key) else { return }

    // Remove from alive set
    aliveTiles.remove(key)

    Engine.onNextFrame {
      // Remove from TileMapLayer
      if let tileMap = tileMapRef {
        tileMap.setCell(
          coords: Vector2i(x: Int32(gridX), y: Int32(gridY)),
          sourceId: -1,
          atlasCoords: Vector2i(x: -1, y: -1),
          alternativeTile: 0
        )
      }

      // Remove the detection area
      node.queueFree()

      // Remove the terrain collision body
      if let collisionBody = collisionBodies.removeValue(forKey: key) {
        collisionBody.queueFree()
      }
    }

    // Call destruction handler with world position
    let center: Vector2 = [
      Float(gridX * gridSize + gridSize / 2),
      Float(gridY * gridSize + gridSize / 2),
    ]
    onDestroyed?(layerOffset + center)
  }
}
