import SwiftGodot

// MARK: - Spacers

public struct Spacer: GView {
  let height: Float

  public init(_ height: Float = 8) {
    self.height = height
  }

  public var body: some GView {
    Control$().minSize([0, height])
  }
}

public struct SpacerV: GView {
  public init() {}

  public var body: some GView {
    Control$().sizeV(.expandFill)
  }
}

public struct SpacerH: GView {
  public init() {}

  public var body: some GView {
    Control$().sizeH(.expandFill)
  }
}

