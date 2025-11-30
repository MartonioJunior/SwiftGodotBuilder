import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  // MARK: - Spacer

  struct Spacer: GView {
    let height: Float

    init(_ height: Float = 8) {
      self.height = height
    }

    var body: some GView {
      Control$().minSize([0, height])
    }
  }

  // MARK: - Button Color

  enum ButtonColor {
    case cyan
    case gray
    case yellow
    case purple
    case green

    func styles(_ palette: Palette) -> [String: StyleBoxFlat$] {
      switch self {
      case .cyan: palette.cyanButtonStylesWithFocus
      case .gray: palette.grayButtonStylesWithFocus
      case .yellow: palette.yellowButtonStylesWithFocus
      case .purple: palette.purpleButtonStylesWithFocus
      case .green: palette.greenButtonStylesWithFocus
      }
    }
  }

  // MARK: - Menu Button

  struct MenuButton: GView {
    let text: String
    let width: Float
    let color: ButtonColor
    let action: () -> Void
    let buttonRef: State<Button?>?

    let palette = Palette.shared

    init(_ text: String, width: Float = 200, color: ButtonColor = .cyan, ref: State<Button?>? = nil, action: @escaping () -> Void) {
      self.text = text
      self.width = width
      self.color = color
      buttonRef = ref
      self.action = action
    }

    var body: some GView {
      Button$()
        .text(text)
        .minSize([width, 0])
        .focusMode(.all)
        .styleBoxes(color.styles(palette))
        .onSignal(\.pressed) { _ in action() }
        .onReady { [buttonRef] in buttonRef?.wrappedValue = $0 }
    }
  }

  // MARK: - Header Label

  struct HeaderLabel: GView {
    let text: String
    let size: Int
    let color: Color

    let palette = Palette.shared

    init(_ text: String, size: Int = 32, color: Color? = nil) {
      self.text = text
      self.size = size
      self.color = color ?? Palette.shared.white
    }

    var body: some GView {
      Label$()
        .text(text)
        .horizontalAlignment(.center)
        .theme(["fontSize": size, "fontColor": color])
    }
  }

  // MARK: - Info Label (static text)

  struct InfoLabel: GView {
    let text: String
    let color: Color

    init(_ text: String, color: Color? = nil) {
      self.text = text
      self.color = color ?? Palette.shared.darkGray
    }

    var body: some GView {
      Label$()
        .text(text)
        .horizontalAlignment(.center)
        .theme(["fontColor": color])
    }
  }

  // MARK: - Info Label (reactive text from ObservableState)

  struct LiveInfoLabel<O: AnyObject & Observable>: GView {
    let text: ObservableProperty<O, String>
    let color: Color

    init(_ text: ObservableProperty<O, String>, color: Color? = nil) {
      self.text = text
      self.color = color ?? Palette.shared.darkGray
    }

    var body: some GView {
      Label$()
        .text(text)
        .horizontalAlignment(.center)
        .theme(["fontColor": color])
    }
  }
}
