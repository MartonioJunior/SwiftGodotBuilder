import SwiftGodot
import SwiftGodotBuilder

#initSwiftExtension(
  cdecl: "swift_entry_point",
  types: [
    LevelDesigner.self,
    AsteroidsGame.self,
    PongGame.self,
    MinimalGame.self,
    BreakoutGame.self,
    SpaceInvadersGame.self,
    PlatformerGame.self,
    Chapter1Game.self,
    Chapter2Game.self,
    Chapter3Game.self,
    Chapter4Game.self,
    Chapter5Game.self,
    Chapter6Game.self,
    Chapter7Game.self,
  ] + BuilderRegistry.types
)
