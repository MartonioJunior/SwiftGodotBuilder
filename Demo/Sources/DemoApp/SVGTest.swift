
import Observation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class SVGTest: Node2D {
  override func _ready() {
    let rootNode = SVGTestView().toNode()
    addChild(node: rootNode)
  }
}

// MARK: - State

@Observable
class SVGDemoState {
  var wobbleAmount: Double = 3
  var pulseSpeed: Double = 2
  var explosionProgress: Double = 0
  var scatterProgress: Double = 0
  var twistAmount: Double = 0.5
  var waveAmplitude: Double = 3
  var noiseAmount: Double = 1
}

// MARK: - Main View

struct SVGTestView: GView {
  let state = ObservableState(wrappedValue: SVGDemoState())

  var body: some GView {
    CanvasLayer$ {
      VBoxContainer$ {
        ControlPanel(state: state)
        ScrollContainer$ {
          VBoxContainer$ {
            Row1ColorEffects(state: state)
            Row2Oscillating(state: state)
            Row3OneShot(state: state)
            Row4Combinations()
          }
          .theme(["separation": 8])
        }
        .horizontalScrollMode(.disabled)
        .sizeFlagsVertical(.expandFill)
      }
      .anchors(.fullRect)
    }
  }
}

// MARK: - Row 1: Color effects

struct Row1ColorEffects: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Static") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.gold, .orange, .yellow])
          .position([16, 16])
      }

      LabeledCell("ColorCycle") {
        SVGSprite$()
          .path("svg/star.svg")
          .position([16, 16])
          .colorCycle([.red, .orange, .yellow, .green, .cyan, .purple], speed: 0.5)
      }

      LabeledCell("StrokeCycle") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.white, .lightGray, .silver])
          .stroke(.white, width: 2)
          .position([16, 16])
          .strokeCycle([.cyan, .blue, .purple], speed: 0.8)
      }

      LabeledCell("DualCycle") {
        SVGSprite$()
          .path("svg/star.svg")
          .stroke(.white, width: 2)
          .position([16, 16])
          .dualColorCycle(fill: [.red, .orange, .yellow], stroke: [.cyan, .white])
      }

      LabeledCell("Pulse") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.red, .darkRed, .crimson])
          .stroke(.darkRed, width: 2)
          .position([16, 16])
          .pulse(speed: state.pulseSpeed)
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Row 2: Oscillating effects (time-based, automatic)

struct Row2Oscillating: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Wobble") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.limeGreen, .green, .darkGreen])
          .stroke(.green, width: 1)
          .position([16, 16])
          .wobble(amount: state.wobbleAmount)
      }

      LabeledCell("Wave") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.orangeRed, .orange, .yellow])
          .stroke(.orange, width: 1)
          .position([16, 16])
          .wave(amplitude: state.waveAmplitude, frequency: 0.2, speed: 3.0)
      }

      LabeledCell("Inflate") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.skyBlue, .white, .gold])
          .stroke(.white, width: 1)
          .position([16, 16])
          .inflate(amount: 4.0, speed: 2.0)
      }

      LabeledCell("Ripple") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.aqua, .teal, .darkCyan])
          .stroke(.teal, width: 2)
          .position([16, 16])
          .ripple(amplitude: 2.0, frequency: 0.4, speed: 4.0)
      }

      LabeledCell("Skew") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.yellow, .gold, .orange])
          .stroke(.gold, width: 1)
          .position([16, 16])
          .skew(amount: 0.4, speed: 1.5)
      }

      LabeledCell("Twist") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.orange, .yellow, .gold])
          .stroke(.gold, width: 1)
          .position([16, 16])
          .twist(amount: state.twistAmount, speed: 2.0)
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Row 3: One-shot effects (progress-driven)

struct Row3OneShot: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Explode") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.orange, .red, .yellow])
          .stroke(.gold, width: 1)
          .position([16, 16])
          .explode(progress: state.explosionProgress)
      }

      LabeledCell("Scatter") {
        SVGSprite$()
          .path("svg/water.svg")
          .colors([.orange, .red, .yellow])
          .stroke(.white, width: 1)
          .position([16, 16])
          .scatter(progress: state.scatterProgress, scale: 30.0)
      }

      LabeledCell("Noise") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.white, .lightGray, .gray])
          .stroke(.crimson, width: 1)
          .position([16, 16])
          .noise(amount: state.noiseAmount, speed: 15.0)
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Row 4: Composable combinations

struct Row4Combinations: GView {
  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Pulse+Wob") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.hotPink, .deepPink, .pink])
          .stroke(.deepPink, width: 2)
          .position([16, 16])
          .svgEffects {
            SVGPulse(speed: 2.0)
            SVGWobble(amount: 2.0)
          }
      }

      LabeledCell("Color+Wave") {
        SVGSprite$()
          .path("svg/star.svg")
          .stroke(.orange, width: 1)
          .position([16, 16])
          .svgEffects {
            SVGColorCycle([.red, .orange, .yellow], speed: 0.5)
            SVGWave(amplitude: 2.0)
          }
      }

      LabeledCell("Infl+Noise") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.limeGreen, .green, .darkGreen])
          .stroke(.darkGreen, width: 1)
          .position([16, 16])
          .svgEffects {
            SVGInflate(amount: 3.0, speed: 3.0)
            SVGNoise(amount: 1.5, speed: 20.0)
          }
      }

      LabeledCell("Skew+Rip") {
        SVGSprite$()
          .path("svg/star.svg")
          .colors([.dodgerBlue, .deepSkyBlue, .lightBlue])
          .stroke(.deepSkyBlue, width: 1)
          .position([16, 16])
          .svgEffects {
            SVGSkew(amount: 0.2, speed: 1.0)
            SVGRipple(amplitude: 1.5, frequency: 0.5, speed: 3.0)
          }
      }

      LabeledCell("Twist+Col") {
        SVGSprite$()
          .path("svg/star.svg")
          .stroke(.white, width: 2)
          .position([16, 16])
          .svgEffects {
            SVGTwist(amount: 0.8, speed: 3.0)
            SVGColorCycle([.green, .limeGreen, .yellow], speed: 1.0)
          }
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Labeled Cell

struct LabeledCell<Content: GView>: GView {
  let label: String
  let content: Content

  init(_ label: String, content: () -> Content) {
    self.label = label
    self.content = content()
  }

  var body: some GView {
    VBoxContainer$ {
      Control$ { content }.minSize([64, 64])
      Label$().text(label).horizontalAlignment(.center).minSize([64, 0])
    }
    .theme(["separation": 0])
  }
}

// MARK: - Control Panel

struct ControlPanel: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      Control$().sizeFlagsHorizontal(.expandFill)
      VBoxContainer$ {
        HBoxContainer$ {
          Label$().text("Wobble").minSize([50, 0])
          HSlider$()
            .minValue(0)
            .maxValue(1)
            .step(0.1)
            .value(state.wobbleAmount)
            .minSize([60, 0])

          Label$().text("Pulse").minSize([40, 0])
          HSlider$()
            .minValue(0)
            .maxValue(10)
            .step(0.1)
            .value(state.pulseSpeed)
            .minSize([60, 0])

          Label$().text("Explode").minSize([50, 0])
          HSlider$()
            .minValue(0)
            .maxValue(0.8)
            .step(0.01)
            .value(state.explosionProgress)
            .minSize([60, 0])
        }

        HBoxContainer$ {
          Label$().text("Scatter").minSize([50, 0])
          HSlider$()
            .minValue(0)
            .maxValue(0.8)
            .step(0.01)
            .value(state.scatterProgress)
            .minSize([60, 0])

          Label$().text("Twist").minSize([40, 0])
          HSlider$()
            .minValue(0)
            .maxValue(2)
            .step(0.05)
            .value(state.twistAmount)
            .minSize([60, 0])

          Label$().text("Wave").minSize([40, 0])
          HSlider$()
            .minValue(0)
            .maxValue(10)
            .step(0.1)
            .value(state.waveAmplitude)
            .minSize([60, 0])

          Label$().text("Noise").minSize([40, 0])
          HSlider$()
            .minValue(0)
            .maxValue(5)
            .step(0.1)
            .value(state.noiseAmount)
            .minSize([60, 0])
        }
      }
      .theme(["separation": 4])
      .minSize([0, 56])
      Control$().sizeFlagsHorizontal(.expandFill)
    }
  }
}
