import Foundation
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
  var wobbleAmount: Double = 1
  var pulseSpeed: Double = 2
  var explosionProgress: Double = 0
  var scatterProgress: Double = 0
  var twistAmount: Double = 0.5
  var waveAmplitude: Double = 3
  var noiseAmount: Double = 1
  var skewAmount: Double = 0.3
  var inflateAmount: Double = 3
  var rippleAmplitude: Double = 2

  // Paths for each sprite (20 total: 5 per row × 4 rows)
  var paths: [String] = Array(repeating: "svg/star.svg", count: 20)

  private var svgFiles: [String] = []

  func randomizeAll() {
    loadSvgFiles()
    for i in 0 ..< paths.count {
      if let file = svgFiles.randomElement() {
        paths[i] = "svg/\(file)"
      }
    }
  }

  func pickRandom(_ index: Int) {
    loadSvgFiles()
    guard let file = svgFiles.randomElement() else { return }
    paths[index] = "svg/\(file)"
  }

  private func loadSvgFiles() {
    guard svgFiles.isEmpty else { return }
    let files = DirAccess.getFilesAt(path: "res://svg/")
    for i in 0 ..< Int(files.size()) {
      let name = String(files[i])
      if name.hasSuffix(".svg") {
        svgFiles.append(name)
      }
    }
  }
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
            Row2Deformations(state: state)
            Row3GameEffects(state: state)
            Row4Combinations(state: state)
          }
          .theme(["separation": 8])
        }
        .horizontalScrollMode(.disabled)
        .sizeFlagsVertical(.expandFill)
      }
      .anchors(.fullRect)
      .onReady { _ in state.wrappedValue.randomizeAll() }
    }
  }
}

// MARK: - Row 1: Static + Color effects

struct Row1ColorEffects: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Static") {
        Button$ {
          SVGSprite$()
            .path(state.paths[0])
            .colors([.purple, .magenta, .violet])
            .position([16, 16])
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(0) }
      }

      LabeledCell("Pulse") {
        Button$ {
          SVGSprite$()
            .path(state.paths[1])
            .colors([.yellow, .gold, .orange])
            .position([16, 16])
            .pulse(speed: state.pulseSpeed)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(1) }
      }

      LabeledCell("ColorCycle") {
        Button$ {
          SVGSprite$()
            .path(state.paths[2])
            .position([16, 16])
            .colorCycle([.red, .orange, .yellow, .green, .blue, .purple], speed: 0.5)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(2) }
      }

      LabeledCell("StrokeCycle") {
        Button$ {
          SVGSprite$()
            .path(state.paths[3])
            .colors([.white, .lightGray, .lightGray])
            .stroke(.white, width: 2)
            .position([16, 16])
            .strokeCycle([.cyan, .blue, .purple], speed: 0.8)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(3) }
      }

      LabeledCell("DualCycle") {
        Button$ {
          SVGSprite$()
            .path(state.paths[4])
            .stroke(.white, width: 2)
            .position([16, 16])
            .dualColorCycle(fill: [.red, .orange, .yellow], stroke: [.cyan, .white])
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(4) }
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Row 2: Basic vertex deformations

struct Row2Deformations: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Wobble") {
        Button$ {
          SVGSprite$()
            .path(state.paths[5])
            .colors([.red, .darkRed, .crimson])
            .position([16, 16])
            .wobble(amount: state.wobbleAmount)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(5) }
      }

      LabeledCell("Explode") {
        Button$ {
          SVGSprite$()
            .path(state.paths[6])
            .colors([.gray, .darkGray, .lightGray])
            .position([16, 16])
            .explode(progress: state.explosionProgress)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(6) }
      }

      LabeledCell("Wave") {
        Button$ {
          SVGSprite$()
            .path(state.paths[7])
            .colors([.orangeRed, .orange, .yellow])
            .position([16, 16])
            .wave(amplitude: state.waveAmplitude, frequency: 0.2, speed: 3.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(7) }
      }

      LabeledCell("Inflate") {
        Button$ {
          SVGSprite$()
            .path(state.paths[8])
            .colors([.steelBlue, .lightSteelBlue, .slateGray])
            .position([16, 16])
            .inflate(amount: state.inflateAmount, speed: 2.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(8) }
      }

      LabeledCell("Ripple") {
        Button$ {
          SVGSprite$()
            .path(state.paths[9])
            .colors([.aqua, .teal, .darkCyan])
            .position([16, 16])
            .ripple(amplitude: state.rippleAmplitude, frequency: 0.4, speed: 4.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(9) }
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Row 3: Game-focused effects

struct Row3GameEffects: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Skew") {
        Button$ {
          SVGSprite$()
            .path(state.paths[10])
            .colors([.green, .limeGreen, .darkGreen])
            .position([16, 16])
            .skew(amount: state.skewAmount, speed: 1.5)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(10) }
      }

      LabeledCell("Noise") {
        Button$ {
          SVGSprite$()
            .path(state.paths[11])
            .colors([.cyan, .white, .lightCyan])
            .position([16, 16])
            .noise(amount: state.noiseAmount, speed: 15.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(11) }
      }

      LabeledCell("Twist") {
        Button$ {
          SVGSprite$()
            .path(state.paths[12])
            .colors([.purple, .magenta, .violet])
            .position([16, 16])
            .twist(amount: state.twistAmount, speed: 2.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(12) }
      }

      LabeledCell("Scatter") {
        Button$ {
          SVGSprite$()
            .path(state.paths[13])
            .colors([.orange, .red, .yellow])
            .position([16, 16])
            .scatter(progress: state.scatterProgress, scale: 30.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(13) }
      }

      LabeledCell("Spin") {
        Button$ {
          SVGSprite$()
            .path(state.paths[14])
            .colors([.gold, .yellow, .orange])
            .position([16, 16])
            .twist(amount: 1.0, speed: 3.0)
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(14) }
      }
    }
    .theme(["separation": 8])
  }
}

// MARK: - Row 4: Composable combinations

struct Row4Combinations: GView {
  let state: ObservableState<SVGDemoState>

  var body: some GView {
    HBoxContainer$ {
      LabeledCell("Pulse+Wob") {
        Button$ {
          SVGSprite$()
            .path(state.paths[15])
            .colors([.hotPink, .deepPink, .pink])
            .position([16, 16])
            .svgEffects {
              SVGPulse(speed: state.pulseSpeed)
              SVGWobble(amount: state.wobbleAmount)
            }
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(15) }
      }

      LabeledCell("Color+Wave") {
        Button$ {
          SVGSprite$()
            .path(state.paths[16])
            .position([16, 16])
            .svgEffects {
              SVGColorCycle([.green, .limeGreen, .darkGreen], speed: 0.5)
              SVGWave(amplitude: 2.0)
            }
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(16) }
      }

      LabeledCell("Infl+Noise") {
        Button$ {
          SVGSprite$()
            .path(state.paths[17])
            .colors([.yellow, .white])
            .position([16, 16])
            .svgEffects {
              SVGInflate(amount: 3.0, speed: 3.0)
              SVGNoise(amount: 1.5, speed: 20.0)
            }
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(17) }
      }

      LabeledCell("Skew+Rip") {
        Button$ {
          SVGSprite$()
            .path(state.paths[18])
            .colors([.dodgerBlue, .deepSkyBlue, .lightBlue])
            .position([16, 16])
            .svgEffects {
              SVGSkew(amount: 0.2, speed: 1.0)
              SVGRipple(amplitude: 1.5, frequency: 0.5, speed: 3.0)
            }
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(18) }
      }

      LabeledCell("Twist+Col") {
        Button$ {
          SVGSprite$()
            .path(state.paths[19])
            .position([16, 16])
            .svgEffects {
              SVGTwist(amount: 0.8, speed: 3.0)
              SVGColorCycle([.purple, .magenta, .cyan], speed: 1.0)
            }
        }
        .flat(true).focusMode(.none).minSize([64, 64])
        .onSignal(\.pressed) { _ in state.wrappedValue.pickRandom(19) }
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
      content
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
            .maxValue(2)
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

        HBoxContainer$ {
          Label$().text("Skew").minSize([50, 0])
          HSlider$()
            .minValue(0)
            .maxValue(1)
            .step(0.05)
            .value(state.skewAmount)
            .minSize([60, 0])

          Label$().text("Inflate").minSize([40, 0])
          HSlider$()
            .minValue(0)
            .maxValue(8)
            .step(0.1)
            .value(state.inflateAmount)
            .minSize([60, 0])

          Label$().text("Ripple").minSize([40, 0])
          HSlider$()
            .minValue(0)
            .maxValue(5)
            .step(0.1)
            .value(state.rippleAmplitude)
            .minSize([60, 0])
        }
      }
      .theme(["separation": 4])
      .minSize([0, 80])
      Control$().sizeFlagsHorizontal(.expandFill)
    }
  }
}
