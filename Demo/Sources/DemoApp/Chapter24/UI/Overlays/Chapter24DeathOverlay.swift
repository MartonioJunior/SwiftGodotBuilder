import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct DeathOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>

    let palette = Palette.shared

    @State var overlayNode: Control?
    @State var textNode: Label?
    @State var animationStarted = false

    private var vm: GameViewState { state.wrappedValue }

    var body: some GView {
      Control$ {
        // Dark overlay that fades in
        ColorRect$()
          .color(Color(r: 0, g: 0, b: 0, a: 0.7))
          .anchorsAndOffsets(.fullRect)

        CenterContainer$ {
          VBoxContainer$ {
            // Death message
            Label$()
              .text("YOU DIED")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.redLight])
              .ref($textNode)

            Spacer(8)

            // Lives remaining
            Label$()
              .text(state, \.livesRemainingText)
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.yellow])
          }
          .theme(["separation": 0])
        }
        .anchorsAndOffsets(.fullRect)
      }
      .anchorsAndOffsets(.fullRect)
      .ref($overlayNode)
      .modulate(Color(r: 1, g: 1, b: 1, a: 0))
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .death
        if scene == .death, !animationStarted {
          animationStarted = true
          playDeathAnimation()
        }
      }
    }

    func playDeathAnimation() {
      // Fade in the overlay
      overlayNode?.tween(.alpha(1.0), duration: 0.3).ease(.out)

      // Shake the text
      textNode?.tween { seq in
        seq.to(.positionX(-5), duration: 0.05)
          .to(.positionX(5), duration: 0.05)
          .to(.positionX(-3), duration: 0.05)
          .to(.positionX(3), duration: 0.05)
          .to(.positionX(0), duration: 0.05)
      }

      // After a brief pause, start the respawn transition
      Engine.onNextFrame {
        overlayNode?.tween { seq in
          seq.to(.alpha(0.0), duration: 0.3).delay(1.2).ease(.in)
        }
        .onFinished {
          animationStarted = false
          router.navigate(to: .playing, transition: .iris(duration: 0.8, center: [0.5, 0.5])) {
            vm.respawnAfterDeath()
          }
        }
      }
    }
  }
}
