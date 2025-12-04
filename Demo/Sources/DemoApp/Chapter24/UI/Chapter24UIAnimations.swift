import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  // MARK: - Animated Button

  /// A button with hover and press animations
  struct AnimatedButton: GView {
    let text: String
    let width: Float
    let color: ButtonColor
    let action: () -> Void
    let buttonRef: State<Button?>?

    let palette = Palette.shared

    let hoverScale: Float = 1.05
    let pressScale: Float = 0.95
    let duration: Double = 0.1

    @State var tween: TweenHandle?

    init(
      _ text: String,
      width: Float = 100,
      color: ButtonColor = .cyan,
      ref: State<Button?>? = nil,
      action: @escaping () -> Void
    ) {
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
        .pivotOffset([width / 2, 12])
        .onSignal(\.pressed) { _ in
          action()
        }
        .onSignal(\.mouseEntered) {
          tween = $0.tween(.scale([hoverScale, hoverScale]), duration: duration, killing: tween).ease(.out)
        }
        .onSignal(\.mouseExited) {
          tween = $0.tween(.scale([1, 1]), duration: duration, killing: tween).ease(.out)
        }
        .onSignal(\.buttonDown) {
          tween = $0.tween(.scale([pressScale, pressScale]), duration: duration, killing: tween).ease(.out)
        }
        .onSignal(\.buttonUp) {
          tween = $0.tween(.scale([hoverScale, hoverScale]), duration: duration, killing: tween).ease(.out)
        }
        .onSignal(\.focusEntered) {
          tween = $0.tween(.scale([hoverScale, hoverScale]), duration: duration, killing: tween).ease(.out)
        }
        .onSignal(\.focusExited) {
          tween = $0.tween(.scale([1, 1]), duration: duration, killing: tween).ease(.out)
        }
        .onReady { buttonRef?.wrappedValue = $0 }
    }
  }

  // MARK: - Bounce Button

  /// A button that bounces when pressed
  struct BounceButton: GView {
    let text: String
    let width: Float
    let color: ButtonColor
    let action: () -> Void
    let buttonRef: State<Button?>?

    let palette = Palette.shared

    @State var tween: SequenceHandle?

    init(
      _ text: String,
      width: Float = 100,
      color: ButtonColor = .cyan,
      ref: State<Button?>? = nil,
      action: @escaping () -> Void
    ) {
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
        .pivotOffset([width / 2, 24])
        .onSignal(\.pressed) { btn in
          tween?.kill()
          tween = btn.tween { seq in
            seq.to(.scale([1.0, 0.8]), duration: 0.05).ease(.out)
              .to(.scale([1.0, 1.15]), duration: 0.08).ease(.out)
              .to(.scale([1.0, 1.0]), duration: 0.12).trans(.bounce).ease(.out)
          }
          action()
        }
        .onReady { buttonRef?.wrappedValue = $0 }
    }
  }
}
