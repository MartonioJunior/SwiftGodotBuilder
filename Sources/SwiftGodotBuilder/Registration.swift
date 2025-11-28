import SwiftGodot

public enum BuilderRegistry {
  public static let types: [Object.Type] = [
    AseSprite.self,
    BfxrSound.self,
    ColorBox.self,
    GProcessRelay.self,
    GEventRelay.self,
    SVGSprite.self,
  ]
}
