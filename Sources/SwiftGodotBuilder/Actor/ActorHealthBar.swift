import SwiftGodot

/// Health bar displayed above an actor's head
public struct ActorHealthBar: GView {
  public let state: ObservableState<ActorState>
  public let config: HealthBarConfig

  private var actor: ActorState { state.wrappedValue }

  private var offsetY: Float {
    -actor.collisionSize.y - config.barHeight - 8
  }

  private var backgroundStyle: StyleBoxFlat {
    StyleBoxFlat$()
      .bgColor(config.backgroundColor)
      .borderColor(config.borderColor)
      .borderWidth(1)
      .cornerRadius(1)
      .toObject()
  }

  private var fillStyle: StyleBoxFlat {
    StyleBoxFlat$()
      .bgColor(config.fillColor)
      .cornerRadius(1)
      .expandMargin(-1)
      .toObject()
  }

  public init(state: ObservableState<ActorState>, config: HealthBarConfig) {
    self.state = state
    self.config = config
  }

  public var body: some GView {
    Node2D$ {
      Control$ {
        // Name label (optional)
        if let name = config.name {
          Label$()
            .text(name)
            .horizontalAlignment(.center)
            .anchors(.topWide)
            .offset(top: -14, right: 0, bottom: 0, left: 0)
            .theme(["fontSize": 8])
        }

        // Health bar
        ProgressBar$()
          .minValue(0)
          .maxValue(Double(actor.maxHealth))
          .value(Double(actor.health))
          .showPercentage(false)
          .anchors(.topWide)
          .minSize([config.barWidth, config.barHeight])
          .theme("background", backgroundStyle)
          .theme("fill", fillStyle)
          .onProcess { [state] bar, _ in
            bar.value = Double(state.wrappedValue.health)
          }
      }
      .minSize([config.barWidth, config.barHeight])
    }
    .position([-config.barWidth / 2, offsetY])
    .onProcess { [config, state] node, _ in
      if config.showWhenFull {
        node.visible = true
      } else {
        node.visible = state.wrappedValue.health < state.wrappedValue.maxHealth
      }
    }
  }
}

// MARK: - Health Bar Config

/// Configuration for health bar appearance
public struct HealthBarConfig: Sendable {
  public var name: String?
  public var showWhenFull: Bool
  public var barWidth: Float
  public var barHeight: Float
  public var fillColor: Color
  public var backgroundColor: Color
  public var borderColor: Color

  public init(
    name: String? = nil,
    showWhenFull: Bool = true,
    barWidth: Float = 32,
    barHeight: Float = 4,
    fillColor: Color = .red,
    backgroundColor: Color = Color(r: 0.1, g: 0.1, b: 0.1, a: 0.8),
    borderColor: Color = .white
  ) {
    self.name = name
    self.showWhenFull = showWhenFull
    self.barWidth = barWidth
    self.barHeight = barHeight
    self.fillColor = fillColor
    self.backgroundColor = backgroundColor
    self.borderColor = borderColor
  }
}
