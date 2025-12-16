import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct BossHealthBarView: GView {
    let boss: ObservableState<BossState>

    let barWidth: Float = 200
    let barHeight: Float = 12

    var bs: BossState { boss.wrappedValue }

    @State var phaseColor = Color(code: "#CC2222")
    @State var phaseLabel = "PHASE 1"
    @State var healthLabel = "HP: 100"
    @State var isVisible = false

    let palette = Palette.shared
    let bossHealthFill: GState<StyleBoxFlat>

    var bossHealthBackground: StyleBoxFlat {
      StyleBoxFlat$()
        .bgColor(Color(r: 0.1, g: 0.1, b: 0.1, a: 0.9))
        .borderColor(palette.white)
        .borderWidth(2)
        .cornerRadius(2)
        .toObject()
    }

    init(boss: ObservableState<BossState>) {
      self.boss = boss

      bossHealthFill = _phaseColor.computed { color in
        StyleBoxFlat$()
          .bgColor(color)
          .cornerRadius(2)
          .expandMargin(-2)
          .toObject()
      }
    }

    var body: some GView {
      VBoxContainer$ {
        Label$()
          .text("THE GUARDIAN")
          .horizontalAlignment(.center)
          .theme(["fontSize": 12, "fontColor": palette.red])

        CenterContainer$ {
          ProgressBar$()
            .minValue(0)
            .maxValue(Double(max(bs.bossMaxHealth, 1)))
            .value(Double(bs.bossHealth))
            .showPercentage(false)
            .minSize([barWidth, barHeight])
            .theme("background", bossHealthBackground)
            .theme("fill", bossHealthFill)
            .watch(boss, \.bossHealth) { bar, health in
              bar.value = Double(health)
            }
            .watch(boss, \.bossMaxHealth) { bar, maxHealth in
              let clampedMax = max(maxHealth, 1)
              bar.maxValue = Double(clampedMax)
            }
        }

        Label$()
          .text($phaseLabel)
          .horizontalAlignment(.center)
          .theme(["fontSize": 8, "fontColor": palette.yellow])

        Label$()
          .text($healthLabel)
          .horizontalAlignment(.center)
          .theme(["fontSize": 8, "fontColor": palette.lightGray])
      }
      .theme(["separation": 2])
      .anchors(.topWide)
      .offset(top: 30, right: 0, bottom: 0, left: 0)
      .visible($isVisible)
      .onReady { _ in
        isVisible = bs.isBossFight
        healthLabel = "HP: \(bs.bossHealth)"
      }
      .watch(boss, \.isBossFight) { _, isBoss in
        isVisible = isBoss
      }
      .watch(boss, \.bossHealth) { _, health in
        healthLabel = "HP: \(health)"
      }
      .watch(boss, \.bossPhase) { _, phase in
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
