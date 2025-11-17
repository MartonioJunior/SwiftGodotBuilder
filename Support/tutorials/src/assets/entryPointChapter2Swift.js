export default `import SwiftGodot

#initSwiftExtension(cdecl: "swift_entry_point", types: [
  Game.self,
  Player.self,
  Item.self,
  BuilderRegistry.getTypes()
])`;
