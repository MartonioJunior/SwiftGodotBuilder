import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct BreakableTerrainView: GView {
    let layer: LDLayer
    let project: LDProject

    var body: some GView {
      LDBreakableTerrainView(layer: layer, project: project)
        .terrainCollisionLayer(Physics2DLayer.terrain.rawValue)
        .detectionMask(Physics2DLayer.combat.rawValue)
        .onTileDestroyed { position in
          GameEvent.terrainDestroyed(position: position).emit()
        }
    }
  }
}
