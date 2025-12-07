import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  /// A tile layer where tiles can be destroyed by combat interactions.
  /// When a tile is hit, it's removed from the TileMapLayer, revealing whatever is behind it.
  struct BreakableTerrainView: GView {
    let layer: LDLayer
    let project: LDProject

    // Track which tile grid positions are still alive
    @State var aliveTiles: Set<String> = []

    // Reference to the TileMapLayer so we can remove tiles
    @State var tileMapRef: TileMapLayer? = nil

    // References to collision bodies keyed by "gridX_gridY"
    @State var collisionBodies: [String: StaticBody2D] = [:]

    var gridSize: Int { layer.gridSize }

    var body: some GView {
      Node2D$()
        .position(layer.totalOffset)
        .onReady { node in
          // Initialize alive tiles set
          var tiles = Set<String>()
          for tile in layer.allTiles {
            let gridX = tile.px[0] / gridSize
            let gridY = tile.px[1] / gridSize
            tiles.insert("\(gridX)_\(gridY)")
          }
          aliveTiles = tiles

          // Defer adding children to next frame to avoid "busy setting up children" error
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
                Float(tile.px[1]) + Float(gridSize) / 2
              ]

              // Combat hit detection (Area2D)
              let areaNode = Area2D$ {
                CollisionShape2D$()
                  .shape(RectangleShape2D(w: Float(gridSize), h: Float(gridSize)))
              }
              .position(tileCenter)
              .collisionLayer(0)
              .collisionMask(.combat)
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
              .collisionLayer(.terrain)
              .collisionMask(0)
              .toNode() as! StaticBody2D

              node.addChild(node: collisionBody)
              collisionBodies[key] = collisionBody
            }
          }
        }
        .onEvent(GameEvent.self) { _, event in
          if case .gameReset = event {
            resetTiles()
          }
        }
    }

    func buildTileMapLayer() -> TileMapLayer? {
      guard let projectPath = project.projectPath else {
        GD.printErr("BreakableTerrainView: Project must have projectPath set")
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

      GD.printErr("BreakableTerrainView: Failed to build TileMapLayer for '\(layer.identifier)'")
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

        // Disable the combat hit detection area
        if let area = node as? Area2D {
          area.processMode = .disabled
          area.visible = false
        }

        // Disable the terrain collision body
        if let collisionBody = collisionBodies[key] {
          collisionBody.processMode = .disabled
          for i in 0 ..< collisionBody.getChildCount() {
            if let shape = collisionBody.getChild(idx: i) as? CollisionShape2D {
              shape.disabled = true
            }
          }
        }
      }

      // Emit destruction event for particles/sound
      let center: Vector2 = [
        Float(gridX * gridSize + gridSize / 2),
        Float(gridY * gridSize + gridSize / 2)
      ]
      GameEvent.terrainDestroyed(position: layer.totalOffset + center).emit()
    }

    func resetTiles() {
      // Rebuild the tile layer on reset
      // For now, we'll rely on level reload to reset
      // A full implementation would restore all tiles
    }
  }
}
