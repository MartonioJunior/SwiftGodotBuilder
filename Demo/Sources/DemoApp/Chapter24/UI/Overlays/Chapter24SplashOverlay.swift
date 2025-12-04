import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct SplashOverlay: GView {
    let router: ObservableState<GameRouter>

    let palette = Palette.shared

    @State var titleNode: Control?
    @State var colorRectNode: ColorRect?
    @State var promptNode: Label?
    @State var animationStarted = false

    var body: some GView {
      Control$ {
        // Animated background with subtle color shift
        ColorRect$()
          .color(Color(r: 0.05, g: 0.08, b: 0.15, a: 1))
          .anchorsAndOffsets(.fullRect)
          .ref($colorRectNode)

        // Decorative particles in background
        CPUParticles2D$()
          .emitting(true)
          .amount(30)
          .lifetime(4.0)
          .explosiveness(0)
          .direction([0, -1])
          .spread(180)
          .initialVelocityMin(10)
          .initialVelocityMax(30)
          .gravity([0, 0])
          .color(palette.cyan.withAlpha(0.3))
          .emissionRectExtents([214, 120])
          .position([120, 100])

        CenterContainer$ {
          VBoxContainer$ {
            // Game title with glow effect
            Control$ {
              Label$()
                .text("SwiftGodotBuilder")
                .horizontalAlignment(.center)
                .theme(["fontSize": 16, "fontColor": palette.cyan])
                .anchorsAndOffsets(.fullRect)

              // Glow layer
              Label$()
                .text("SwiftGodotBuilder")
                .horizontalAlignment(.center)
                .theme(["fontSize": 16, "fontColor": palette.cyan.withAlpha(0.3)])
                .anchorsAndOffsets(.fullRect)
                .offset(top: 2, right: 2, bottom: -2, left: -2)
            }
            .minSize([220, 45])
            .ref($titleNode)
            .modulate(Color(r: 1, g: 1, b: 1, a: 0))

            Spacer(16)

            Label$()
              .text("PRESS ANY BUTTON")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.white])
              .ref($promptNode)
              .modulate(Color(r: 1, g: 1, b: 1, a: 0))
          }
          .theme(["separation": 0])
        }
        .anchorsAndOffsets(.fullRect)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .splash
        if scene == .splash, !animationStarted {
          animationStarted = true
          startIntroAnimation()
        }
      }
      .onReady { _ in
        if router.scene == .splash {
          animationStarted = true
          startIntroAnimation()
        }
      }
      .onProcess { _, _ in
        guard router.scene == .splash else { return }
        if Action("ui_accept").isJustPressed ||
          Action("attack").isJustPressed ||
          Action("jump").isJustPressed ||
          Action("pause").isJustPressed
        {
          goToWelcome()
        }
      }
    }

    func startIntroAnimation() {
      Engine.onNextFrame {
        colorRectNode?.tween { seq in
          seq
            .to(.color(Color(r: 0.08, g: 0.05, b: 0.15, a: 1)), duration: 3.0)
            .ease(.inOut)
            .to(.color(Color(r: 0.05, g: 0.08, b: 0.15, a: 1)), duration: 3.0)
            .ease(.inOut)
        }
        .loop()

        titleNode?.tween { seq in
          seq.to(.alpha(1.0), duration: 1.8).ease(.out)
        }

        promptNode?.tween { seq in
          seq.delay(1.0).to(.alpha(1.0), duration: 0.3).ease(.out)
        }

        startPromptPulse()
      }
    }

    func startPromptPulse() {
      promptNode?.tween { seq in
        seq
          .delay(1.5)
          .to(.alpha(0.3), duration: 0.8)
          .trans(.sine)
          .ease(.inOut)
          .to(.alpha(1.0), duration: 0.8)
          .trans(.sine)
          .ease(.inOut)
      }
      .loop()
    }

    func goToWelcome() {
      router.navigate(to: .welcome, transition: .fade()) {
        animationStarted = false
      }
    }
  }
}
