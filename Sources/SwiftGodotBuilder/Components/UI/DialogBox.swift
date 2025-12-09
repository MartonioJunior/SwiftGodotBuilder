import SwiftGodot

/// Wrapper for DialogChoice with Identifiable conformance for ForEach
public struct IndexedChoice: Equatable, Identifiable {
  public let index: Int
  public let text: String
  public var id: Int { index }

  public init(index: Int, text: String) {
    self.index = index
    self.text = text
  }

  public init(from choice: DialogChoice) {
    index = choice.index
    text = choice.text
  }
}

/// A dialog box UI with typewriter text effect and choice buttons.
/// Works with DialogRunner to display dialog content.
public struct DialogBox: GView {
  let isVisible: State<Bool>
  let getDialogRunner: () -> DialogRunner?
  let speakerColors: [String: Color]
  let typewriterSpeed: Float
  let onEnd: () -> Void

  // Dialog colors
  let dialogPurple = Color(code: "#B366FF")
  let panelBg = Color(r: 0.05, g: 0.05, b: 0.1, a: 0.95)

  var dialogPanelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(panelBg)
      .borderColor(dialogPurple)
      .borderWidth(2)
      .cornerRadius(4)
      .contentMargin(8)
  }

  var choiceButtonStyles: [String: StyleBoxFlat$] {
    [
      "normal": StyleBoxFlat$()
        .bgColor(Color(r: 0, g: 0, b: 0, a: 0))
        .borderColor(Color(r: 0, g: 0, b: 0, a: 0))
        .borderWidth(0)
        .cornerRadius(0)
        .contentMargin(2),
      "hover": StyleBoxFlat$()
        .bgColor(dialogPurple.withAlpha(0.2))
        .borderColor(dialogPurple)
        .borderWidth(1)
        .cornerRadius(2)
        .contentMargin(2),
      "pressed": StyleBoxFlat$()
        .bgColor(dialogPurple.withAlpha(0.4))
        .borderColor(dialogPurple)
        .borderWidth(1)
        .cornerRadius(2)
        .contentMargin(2),
      "focus": StyleBoxFlat$()
        .bgColor(dialogPurple.withAlpha(0.3))
        .borderColor(.white)
        .borderWidth(1)
        .cornerRadius(2)
        .contentMargin(2),
    ]
  }

  @State var speakerName = ""
  @State var speakerColor: Color = .white
  @State var displayedText = ""
  @State var fullText = ""
  @State var isTyping = false
  @State var typewriterProgress: Float = 0
  @State var choices: [IndexedChoice] = []
  @State var showChoices = false
  @State var isSetup = false

  public init(
    isVisible: State<Bool>,
    dialogRunner: @escaping () -> DialogRunner?,
    speakerColors: [String: Color] = [:],
    typewriterSpeed: Float = 30.0,
    onEnd: @escaping () -> Void
  ) {
    self.isVisible = isVisible
    getDialogRunner = dialogRunner
    self.speakerColors = speakerColors
    self.typewriterSpeed = typewriterSpeed
    self.onEnd = onEnd
  }

  public var body: some GView {
    Control$ {
      // Semi-transparent background
      ColorRect$()
        .color(Color(r: 0, g: 0, b: 0, a: 0.3))
        .anchorsAndOffsets(.fullRect)

      // Dialog panel at bottom
      VBoxContainer$ {
        SpacerV()

        HBoxContainer$ {
          SpacerH()

          PanelContainer$ {
            VBoxContainer$ {
              // Speaker name
              Label$()
                .text($speakerName)
                .theme(["fontSize": 16])
                .watch($speakerColor) { label, color in
                  label.addThemeColorOverride(name: StringName("font_color"), color: color)
                }

              // Dialog text with typewriter effect
              Label$().text($displayedText)

              SpacerV()

              // Choices container
              VBoxContainer$ {
                ForEach($choices) { item in
                  DialogChoiceButton(
                    item: item,
                    styles: choiceButtonStyles,
                    onSelected: { index in handleChoiceSelected(index) },
                    isFirst: item.wrappedValue.index == 0
                  )
                }
              }
              .theme(["separation": 2])
              .visible($showChoices)
            }
          }
          .theme("panel", dialogPanelStyle)
          .minSize([200, 0])

          SpacerH()
        }
      }
      .anchorsAndOffsets(.fullRect)
      .offset(top: 0, right: -8, bottom: -8, left: 8)
    }
    .anchorsAndOffsets(.fullRect)
    .visible(isVisible)
    .processMode(.always)
    .onProcess { _, delta in
      guard isVisible.wrappedValue else { return }

      // Typewriter effect
      if isTyping {
        typewriterProgress += Float(delta) * typewriterSpeed
        let charCount = Int(typewriterProgress)
        if charCount >= fullText.count {
          displayedText = fullText
          isTyping = false
          showChoices = !choices.isEmpty
        } else {
          displayedText = String(fullText.prefix(charCount))
        }
      }

      // Handle input
      if Action("ui_accept").isJustPressed || Action("jump").isJustPressed {
        if isTyping {
          // Skip to full text
          displayedText = fullText
          isTyping = false
          showChoices = !choices.isEmpty
        } else if !showChoices {
          // Only advance if no choices (choices use focus/buttons)
          advanceDialog()
        }
      }

      // Cancel/skip
      if Action("ui_cancel").isJustPressed {
        endDialog()
      }
    }
    .watch(isVisible) { _, visible in
      if visible, !isSetup {
        isSetup = true
        setupRunnerCallbacks()
      } else if !visible {
        isSetup = false
      }
    }
  }

  func setupRunnerCallbacks() {
    guard let runner = getDialogRunner() else { return }

    runner.onLine = { (line: DialogLine) in
      speakerName = line.speaker
      speakerColor = speakerColors[line.speaker] ?? .white
      fullText = line.text
      displayedText = ""
      typewriterProgress = 0
      isTyping = true
      showChoices = false
      choices = []
    }

    runner.onChoices = { (availableChoices: [DialogChoice]) in
      choices = availableChoices.map { IndexedChoice(from: $0) }
      // Don't show choices until typing is done
      if !isTyping {
        showChoices = true
      }
    }

    runner.onEnd = {
      endDialog()
    }

    // Start the runner after callbacks are set up
    runner.start(branchId: runner.pendingBranchId)
  }

  func advanceDialog() {
    getDialogRunner()?.advance()
  }

  func handleChoiceSelected(_ index: Int) {
    getDialogRunner()?.selectChoice(index)
  }

  func endDialog() {
    onEnd()
  }
}

/// A choice button for dialog choices
public struct DialogChoiceButton: GView {
  let item: GState<IndexedChoice>
  let styles: [String: StyleBoxFlat$]
  let onSelected: (Int) -> Void
  let isFirst: Bool

  public init(
    item: GState<IndexedChoice>,
    styles: [String: StyleBoxFlat$],
    onSelected: @escaping (Int) -> Void,
    isFirst: Bool
  ) {
    self.item = item
    self.styles = styles
    self.onSelected = onSelected
    self.isFirst = isFirst
  }

  public var body: some GView {
    Button$()
      .text(item.computed { $0.text })
      .focusMode(.all)
      .styleBoxes(styles)
      .onSignal(\.pressed) { _ in
        onSelected(item.wrappedValue.index)
      }
      .onReady { btn in
        if isFirst {
          btn.grabFocus()
        }
      }
  }
}
