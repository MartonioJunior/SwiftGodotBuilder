import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct CreditsOverlay: GView {
    let router: ObservableState<GameRouter>

    let palette = Palette.shared
    let scrollDuration: Double = 30.0
    let viewportHeight: Float = 240

    @State var creditsContainer: Node2D?
    @State var scrollTween: TweenHandle?
    @State var animationStarted = false

    var creditsText: String {
      """
      [center][color=#00FFFF][font_size=24]CHAPTER 23[/font_size][/color]
      [color=#FFD700]Credits & Splash Screen[/color]

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]CREATED WITH[/font_size][/color]

      [color=#00FFFF]SwiftGodotBuilder[/color]
      Declarative Godot Development

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]PROGRAMMING[/font_size][/color]

      [color=#AAAAAA]John Susek[/color]
      Lead Developer

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]POWERED BY[/font_size][/color]

      [color=#478CBF]Godot Engine[/color]
      Open Source Game Engine

      [color=#F05138]SwiftGodot[/color]
      Swift Language Bindings

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]SPECIAL THANKS[/font_size][/color]

      [color=#AAAAAA]Miguel de Icaza[/color]
      SwiftGodot Creator

      [color=#AAAAAA]SwiftGodot Discord[/color]
      For Feedback and Encouragement

      [color=#888888]─────────────────[/color]

      [color=#FFD700][font_size=16]THANK YOU FOR PLAYING![/font_size][/color]
      """
    }

    var body: some GView {
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
        .position([214, viewportHeight])
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .credits
        if scene == .credits, !animationStarted {
          animationStarted = true
          startCreditsScroll()
        } else if scene != .credits {
          animationStarted = false
          scrollTween?.kill()
        }
      }
      .onProcess { [router] _, _ in
        guard router.scene == .credits else { return }
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
      guard let container = creditsContainer else { return }

      // Reset position to below screen
      container.position = [214, viewportHeight]

      // Scroll up to above screen
      scrollTween = container.tween(.positionY(-600), duration: scrollDuration)
        .trans(.linear)
        .onFinished {
          exitCredits()
        }
    }

    func exitCredits() {
      scrollTween?.kill()
      router.navigate(to: .welcome, transition: .fade()) {
        animationStarted = false
      }
    }
  }
}
