import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  // Wrapper for choices with Identifiable conformance
  struct IndexedChoice: Equatable, Identifiable {
    let index: Int
    let text: String
    var id: Int { index }

    init(from choice: SwiftGodotBuilder.DialogChoice) {
      index = choice.index
      text = choice.text
    }
  }

  struct DialogBox: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>

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

    private var vm: GameViewState { state.wrappedValue }

    @State var speakerName = ""
    @State var speakerColor: Color = .white
    @State var displayedText = ""
    @State var fullText = ""
    @State var isTyping = false
    @State var typewriterProgress: Float = 0
    @State var choices: [IndexedChoice] = []
    @State var showChoices = false

    let typewriterSpeed: Float = 30.0

    var body: some GView {
      Control$ {
        // Semi-transparent background
        ColorRect$()
          .color(Color(r: 0, g: 0, b: 0, a: 0.3))
          .anchorsAndOffsets(.fullRect)

        // Dialog panel at bottom
        VBoxContainer$ {
          Chapter24.SpacerV()

          HBoxContainer$ {
            Chapter24.SpacerH()

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

                Chapter24.SpacerV()

                // Choices container
                VBoxContainer$ {
                  ForEach($choices) { item in
                    ChoiceButton(
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

            Chapter24.SpacerH()
          }
        }
        .anchorsAndOffsets(.fullRect)
        .offset(top: 0, right: -8, bottom: -8, left: 8)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .dialog
      }
      .processMode(.always)
      .onProcess { _, delta in
        guard router.scene == .dialog else { return }

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
      .watch(router, \.scene) { _, scene in
        if scene == .dialog {
          setupRunnerCallbacks()
        }
      }
    }

    func setupRunnerCallbacks() {
      guard let runner = vm.dialogRunner else { return }

      let colors = Chapter24.buildSpeakerColors()

      runner.onLine = { line in
        speakerName = line.speaker
        speakerColor = colors[line.speaker] ?? .white
        fullText = line.text
        displayedText = ""
        typewriterProgress = 0
        isTyping = true
        showChoices = false
        choices = []
      }

      runner.onChoices = { availableChoices in
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
      vm.dialogRunner?.advance()
    }

    func handleChoiceSelected(_ index: Int) {
      vm.dialogRunner?.selectChoice(index)
    }

    func endDialog() {
      if let npcId = vm.currentNPCId {
        DialogEvent.ended(npcId: npcId).emit()
      }
      vm.cleanupDialog()
      router.scene = .playing
    }
  }

  struct ChoiceButton: GView {
    let item: GState<IndexedChoice>
    let styles: [String: StyleBoxFlat$]
    let onSelected: (Int) -> Void
    let isFirst: Bool

    var body: some GView {
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
}
