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

// MARK: - Header Label

public struct HeaderLabel: GView {
  let text: String
  let size: Int
  let color: Color

  public init(_ text: String, size: Int = 24, color: Color? = nil) {
    self.text = text
    self.size = size
    self.color = color ?? Palette.shared.white
  }

  public var body: some GView {
    Label$()
      .text(text)
      .horizontalAlignment(.center)
      .theme(["fontSize": size, "fontColor": color])
  }
}

// MARK: - Info Label (static text)

public struct InfoLabel: GView {
  let text: String
  let color: Color

  public init(_ text: String, color: Color? = nil) {
    self.text = text
    self.color = color ?? Palette.shared.darkGray
  }

  public var body: some GView {
    Label$()
      .text(text)
      .horizontalAlignment(.center)
      .theme(["fontColor": color])
  }
}

// MARK: - Info Label (reactive text from GState)

public struct LiveInfoLabel: GView {
  let text: GState<String>
  let color: Color

  public init(_ text: GState<String>, color: Color? = nil) {
    self.text = text
    self.color = color ?? Palette.shared.darkGray
  }

  public var body: some GView {
    Label$()
      .text(text)
      .horizontalAlignment(.center)
      .theme(["fontColor": color])
  }
}
