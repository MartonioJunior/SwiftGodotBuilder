import SwiftGodot
import SwiftGodotBuilder

extension Chapter16 {
  struct BossHealthBar: GView {
    let state: ObservableState<GameViewState>

    let barWidth: Float = 200
    let barHeight: Float = 16

    @State var phaseColor = Color(code: "#CC2222")
    @State var phaseLabel = "PHASE 1"
    @State var healthLabel = "HP: 100"
    @State var isVisible = false

    let palette = Palette()

    var bossHealthBackground: StyleBoxFlat {
      StyleBoxFlat$()
        .bgColor(Color(r: 0.1, g: 0.1, b: 0.1, a: 0.9))
        .borderColor(palette.white)
        .borderWidth(2)
        .cornerRadius(2)
        .toObject()
    }

    var bossHealthFill: GState<StyleBoxFlat> {
      $phaseColor.computed { color in
        StyleBoxFlat$()
          .bgColor(color)
          .cornerRadius(2)
          .expandMargin(-2)
          .toObject()
      }
    }

    var body: some GView {
      VBoxContainer$ {
        // Boss name/title
        Label$()
          .text("THE GUARDIAN")
          .horizontalAlignment(.center)
          .theme(["fontSize": 12, "fontColor": palette.red])

        HBoxContainer$ {
          Control$().sizeH(.expandFill)

          // Health bar with progress bar
          ProgressBar$()
            .minValue(0)
            .maxValue(100)
            .value(100)
            .showPercentage(false)
            .minSize([barWidth, barHeight])
            .theme("background", bossHealthBackground)
            .theme("fill", bossHealthFill)
            .watch(state, \.bossHealth) { bar, health in
              bar.value = Double(health)
            }

          Control$().sizeH(.expandFill)
        }

        // Phase indicator
        Label$()
          .text($phaseLabel)
          .horizontalAlignment(.center)
          .theme(["fontSize": 8, "fontColor": palette.yellow])

        // Health numbers
        Label$()
          .text($healthLabel)
          .horizontalAlignment(.center)
          .theme(["fontSize": 8, "fontColor": palette.lightGray])
      }
      .theme(["separation": 2])
      .anchors(.topWide)
      .offset(top: 30, right: 0, bottom: 0, left: 0)
      .visible($isVisible)
      .onReady { [self] _ in
        isVisible = state.wrappedValue.isBossFight
        healthLabel = "HP: \(state.wrappedValue.bossHealth)"
      }
      .watch(state, \.isBossFight) { [self] _, isBoss in
        isVisible = isBoss
      }
      .watch(state, \.bossHealth) { [self] _, health in
        healthLabel = "HP: \(health)"
      }
      .watch(state, \.bossPhase) { [self] _, phase in
        switch phase {
        case .one:
          phaseColor = Color(code: "#CC2222")
          phaseLabel = "PHASE 1"
        case .two:
          phaseColor = Color(code: "#FF6600")
          phaseLabel = "PHASE 2"
        case .three:
          phaseColor = Color(code: "#9933FF")
          phaseLabel = "PHASE 3"
        case .defeated:
          phaseColor = Color(code: "#666666")
          phaseLabel = "DEFEATED"
        }
      }
    }
  }
}
