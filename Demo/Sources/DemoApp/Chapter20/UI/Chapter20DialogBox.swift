import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
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
    let state: ObservableState<GameViewState>

    let palette = Palette()

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
          Chapter20.SpacerV()

          HBoxContainer$ {
            Chapter20.SpacerH()

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

                Chapter20.SpacerV()

                // Choices container
                VBoxContainer$ {
                  ForEach($choices) { item in
                    ChoiceButton(
                      item: item,
                      palette: palette,
                      onSelected: { index in handleChoiceSelected(index) },
                      isFirst: item.wrappedValue.index == 0
                    )
                  }
                }
                .theme(["separation": 2])
                .visible($showChoices)
              }
            }
            .theme("panel", palette.dialogPanelStyle)
            .minSize([200, 0])

            Chapter20.SpacerH()
          }
        }
        .anchorsAndOffsets(.fullRect)
        .offset(top: 0, right: -8, bottom: -8, left: 8)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isDialog)
      .processMode(.always)
      .onProcess { _, delta in
        guard state.wrappedValue.isDialog else { return }

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
      .watch(state, \.gameState) { _, gameState in
        if gameState == .dialog {
          setupRunnerCallbacks()
        }
      }
    }

    func setupRunnerCallbacks() {
      guard let runner = state.wrappedValue.dialogRunner else { return }

      let colors = Chapter20.buildSpeakerColors()

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
      state.wrappedValue.dialogRunner?.advance()
    }

    func handleChoiceSelected(_ index: Int) {
      state.wrappedValue.dialogRunner?.selectChoice(index)
    }

    func endDialog() {
      if let npcId = state.wrappedValue.currentNPCId {
        DialogEvent.ended(npcId: npcId).emit()
      }
      state.wrappedValue.endDialog()
    }
  }

  struct ChoiceButton: GView {
    let item: GState<IndexedChoice>
    let palette: Palette
    let onSelected: (Int) -> Void
    let isFirst: Bool

    var body: some GView {
      Button$()
        .text(item.computed { $0.text })
        .focusMode(.all)
        .styleBoxes(palette.choiceButtonStyles)
        .onSignal(\.pressed) { [item, onSelected] _ in
          onSelected(item.wrappedValue.index)
        }
        .onReady { [isFirst] btn in
          if isFirst {
            btn.grabFocus()
          }
        }
    }
  }
}
