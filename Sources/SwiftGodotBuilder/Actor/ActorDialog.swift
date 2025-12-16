import Foundation
import SwiftGodot

// MARK: - Dialog Configuration

/// Who is speaking
public struct DialogSpeaker: Sendable {
  public let name: String
  public let portrait: String?
  public let position: SpeakerPosition

  public enum SpeakerPosition: Sendable {
    case left
    case right
    case center
  }

  public init(name: String, portrait: String? = nil, position: SpeakerPosition = .left) {
    self.name = name
    self.portrait = portrait
    self.position = position
  }

  public static func actor(name: String, portrait: String? = nil) -> DialogSpeaker {
    DialogSpeaker(name: name, portrait: portrait, position: .left)
  }

  public static func npc(_ name: String, portrait: String? = nil) -> DialogSpeaker {
    DialogSpeaker(name: name, portrait: portrait, position: .right)
  }
}

/// A line of actor dialog
public struct ActorDialogLine: Sendable {
  public let speaker: DialogSpeaker
  public let text: String
  public let duration: Double?

  public init(speaker: DialogSpeaker, text: String, duration: Double? = nil) {
    self.speaker = speaker
    self.text = text
    self.duration = duration
  }

  /// Quick line from a named speaker
  public static func line(_ speaker: DialogSpeaker, _ text: String, duration: Double? = nil) -> ActorDialogLine {
    ActorDialogLine(speaker: speaker, text: text, duration: duration)
  }
}

/// A complete actor dialog sequence
public struct ActorDialogSequence: Sendable {
  public let id: String
  public let lines: [ActorDialogLine]

  public init(id: String, lines: [ActorDialogLine]) {
    self.id = id
    self.lines = lines
  }

  public init(id: String, @ActorDialogBuilder lines: () -> [ActorDialogLine]) {
    self.id = id
    self.lines = lines()
  }
}

/// Result builder for actor dialog sequences
@resultBuilder
public struct ActorDialogBuilder {
  public static func buildBlock(_ lines: ActorDialogLine...) -> [ActorDialogLine] {
    lines
  }

  public static func buildArray(_ components: [[ActorDialogLine]]) -> [ActorDialogLine] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [ActorDialogLine]?) -> [ActorDialogLine] {
    component ?? []
  }

  public static func buildEither(first component: [ActorDialogLine]) -> [ActorDialogLine] {
    component
  }

  public static func buildEither(second component: [ActorDialogLine]) -> [ActorDialogLine] {
    component
  }
}

// MARK: - Dialog Events

/// Events for the actor dialog system
public enum ActorDialogEvent: EmittableEvent {
  /// Request to start a dialog sequence
  case startDialog(sequence: ActorDialogSequence, triggeredBy: Int?)

  /// Request to show a single line (for cutscenes)
  case showLine(line: ActorDialogLine)

  /// Dialog was completed
  case dialogEnded(sequenceId: String)

  /// One actor speaks to another
  case actorSpoke(speakerId: Int, targetId: Int?, text: String)
}

// MARK: - Dialog Trigger Component

/// Mutable state for dialog trigger
final class DialogTriggerState {
  var visitCount = 0
  var nearbyInteractor: Area2D?
}

/// Attach to an actor to make them trigger dialog on interaction
public struct ActorDialogTrigger: GView {
  public let actorState: ObservableState<ActorState>
  public let dialogProvider: (Int) -> ActorDialogSequence?

  private let triggerState = DialogTriggerState()

  /// Physics layer for interaction detection
  public var interactionLayer: Physics2DLayer = .gamma

  private var actor: ActorState { actorState.wrappedValue }

  public init(
    actorState: ObservableState<ActorState>,
    interactionLayer: Physics2DLayer = .gamma,
    dialogProvider: @escaping (Int) -> ActorDialogSequence?
  ) {
    self.actorState = actorState
    self.interactionLayer = interactionLayer
    self.dialogProvider = dialogProvider
  }

  public var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: actor.collisionSize * 1.5))
        .position(actor.collisionOffset)
    }
    .collisionLayer(interactionLayer)
    .collisionMask(interactionLayer)
    .monitorable(true)
    .monitoring(true)
    .onSignal(\.areaEntered) { [triggerState] _, area in
      triggerState.nearbyInteractor = area
    }
    .onSignal(\.areaExited) { [triggerState] _, area in
      if area == triggerState.nearbyInteractor {
        triggerState.nearbyInteractor = nil
      }
    }
    .onEvent(ActorDialogEvent.self) { _, _ in
      // Could respond to dialog events here
    }
  }

  public func tryInteract(triggeredById: Int?) -> Bool {
    guard triggerState.nearbyInteractor != nil else { return false }
    guard let sequence = dialogProvider(triggerState.visitCount) else { return false }

    triggerState.visitCount += 1
    ActorDialogEvent.startDialog(sequence: sequence, triggeredBy: triggeredById).emit()
    return true
  }
}

// MARK: - Cutscene Dialog Helper

/// Helper for triggering actor dialog sequences programmatically (cutscenes)
public enum ActorCutsceneDialog {
  /// Make one actor "speak" with a single line
  public static func speak(
    actorId: Int,
    name: String,
    text: String,
    portrait: String? = nil,
    duration: Double? = nil
  ) {
    let line = ActorDialogLine(
      speaker: .actor(name: name, portrait: portrait),
      text: text,
      duration: duration
    )
    ActorDialogEvent.showLine(line: line).emit()
    ActorDialogEvent.actorSpoke(speakerId: actorId, targetId: nil, text: text).emit()
  }

  /// Start a full actor dialog sequence
  public static func startSequence(_ sequence: ActorDialogSequence, triggeredBy actorId: Int? = nil) {
    ActorDialogEvent.startDialog(sequence: sequence, triggeredBy: actorId).emit()
  }
}
