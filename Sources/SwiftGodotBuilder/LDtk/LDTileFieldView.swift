import SwiftGodot

/// Renders sprites from an LDtk tile field, handling multi-tile selections with tiling
public struct LDTileFieldView: GView {
  let tile: LDTilesetRect
  let project: LDProject
  let gridSize: Int
  let tileCountX: Int
  let tileCountY: Int

  /// Create a tile field view from explicit tile counts
  public init(tile: LDTilesetRect, project: LDProject, gridSize: Int, tileCountX: Int, tileCountY: Int) {
    self.tile = tile
    self.project = project
    self.gridSize = gridSize
    self.tileCountX = tileCountX
    self.tileCountY = tileCountY
  }

  /// Create a tile field view from pixel dimensions
  public init(tile: LDTilesetRect, project: LDProject, gridSize: Int, width: Float, height: Float) {
    self.tile = tile
    self.project = project
    self.gridSize = gridSize
    self.tileCountX = Int(width) / gridSize
    self.tileCountY = Int(height) / gridSize
  }

  public var body: some GView {
    Node2D$ {
      if let tilesetDef = project.defs.tileset(uid: tile.tilesetUid),
         let texture = ResourceLoader.load(path: tilesetDef.resourcePath(relativeTo: project.projectPath ?? "")) as? Texture2D
      {
        // Source tile dimensions for tiling pattern
        let sourceTileCountX = tile.w / gridSize
        let sourceTileCountY = tile.h / gridSize

        for y in 0 ..< tileCountY {
          for x in 0 ..< tileCountX {
            let sourceTileX = x % sourceTileCountX
            let sourceTileY = y % sourceTileCountY
            let sourceX = tile.x + (sourceTileX * gridSize)
            let sourceY = tile.y + (sourceTileY * gridSize)

            Sprite2D$()
              .texture(texture)
              .regionEnabled(true)
              .regionRect(Rect2(x: Float(sourceX), y: Float(sourceY), width: Float(gridSize), height: Float(gridSize)))
              .centered(false)
              .position([Float(x * gridSize), Float(y * gridSize)])
          }
        }
      }
    }
  }
}
