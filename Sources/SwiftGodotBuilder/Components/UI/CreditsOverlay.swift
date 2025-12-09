import SwiftGodot

/// A scrolling credits overlay with BBCode support and star particles.
/// Use `isVisible` binding to show/hide, and `onDismiss` for exit handling.
public struct CreditsOverlay: GView {
  let isVisible: State<Bool>
  let creditsText: String
  let scrollDuration: Double
  let onDismiss: () -> Void

  let palette = Palette.shared

  @State var creditsContainer: Node2D?
  @State var scrollTween: TweenHandle?
  @State var animationStarted = false

  public init(
    isVisible: State<Bool>,
    creditsText: String,
    scrollDuration: Double = 30.0,
    onDismiss: @escaping () -> Void
  ) {
    self.isVisible = isVisible
    self.creditsText = creditsText
    self.scrollDuration = scrollDuration
    self.onDismiss = onDismiss
  }

  public var body: some GView {
    Control$ {
      // Background
      ColorRect$()
        .color(Color(r: 0.02, g: 0.02, b: 0.05, a: 1))
        .anchorsAndOffsets(.fullRect)

      // Decorative stars
      CPUParticles2D$()
        .emitting(true)
        .amount(50)
        .lifetime(3.0)
        .explosiveness(0)
        .direction([0, 1])
        .spread(12)
        .initialVelocityMin(5)
        .initialVelocityMax(15)
        .gravity([0, 0])
        .color(palette.white.withAlpha(0.5))
        .emissionRectExtents([214, 10])
        .position([214, 0])

      // Scrolling credits container
      Node2D$ {
        RichTextLabel$()
          .bbcodeEnabled(true)
          .text(creditsText)
          .fitContent(true)
          .scrollActive(false)
          .minSize([400, 800])
          .anchors(.topWide)
          .offset(top: 0, right: -200, bottom: 0, left: -200)
      }
      .ref($creditsContainer)
      .onReady { node in
        let viewportHeight = node.getViewportRect().size.y
        node.position = [214, viewportHeight]
      }
    }
    .anchorsAndOffsets(.fullRect)
    .visible(isVisible)
    .watch(isVisible) { _, visible in
      if visible, !animationStarted {
        animationStarted = true
        startCreditsScroll()
      } else if !visible {
        animationStarted = false
        scrollTween?.kill()
      }
    }
    .onProcess { _, _ in
      guard isVisible.wrappedValue else { return }
      if Action("ui_accept").isJustPressed ||
        Action("ui_cancel").isJustPressed ||
        Action("attack").isJustPressed ||
        Action("pause").isJustPressed
      {
        exitCredits()
      }
    }
  }

  func startCreditsScroll() {
    guard let creditsContainer else { return }

    // Reset position to below screen
    let viewportHeight = creditsContainer.getViewportRect().size.y
    creditsContainer.position = [214, viewportHeight]

    // Scroll up to above screen
    scrollTween = creditsContainer.tween(.positionY(-600), duration: scrollDuration)
      .trans(.linear)
      .onFinished {
        exitCredits()
      }
  }

  func exitCredits() {
    scrollTween?.kill()
    onDismiss()
  }
}
