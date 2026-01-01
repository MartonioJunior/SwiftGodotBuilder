// DialogTests.swift
// Runtime tests for Dialog DSL and state

import SwiftGodot
import SwiftGodotBuilder

struct DialogTests: TestSuite {
  var allTests: [TestInvocation] {
    [
      // Speaker tests
      test("testSpeakerCreation", testSpeakerCreation),
      test("testSpeakerLineOperator", testSpeakerLineOperator),

      // DialogElement tests
      test("testDialogElementLine", testDialogElementLine),
      test("testDialogElementChoice", testDialogElementChoice),
      test("testDialogElementJump", testDialogElementJump),
      test("testDialogElementEmit", testDialogElementEmit),
      test("testDialogElementEnd", testDialogElementEnd),

      // Branch and Dialog tests
      test("testBranchCreation", testBranchCreation),
      test("testDialogCreation", testDialogCreation),
      test("testDialogBranchLookup", testDialogBranchLookup),
      test("testDialogFirstBranch", testDialogFirstBranch),

      // DialogState tests
      test("testDialogStateInitial", testDialogStateInitial),
      test("testDialogStateFirstVisit", testDialogStateFirstVisit),
      test("testDialogStateSubsequentVisits", testDialogStateSubsequentVisits),

      // Complex dialog tests
      test("testComplexDialog", testComplexDialog),
    ]
  }

  // MARK: - Speaker Tests

  func testSpeakerCreation() {
    let guard1 = Speaker("Guard")
    XCTAssertEqual(guard1.name, "Guard")

    let merchant = Speaker("Merchant")
    XCTAssertEqual(merchant.name, "Merchant")
  }

  func testSpeakerLineOperator() {
    let guard1 = Speaker("Guard")
    let element = guard1 ~ "Halt! Who goes there?"

    if case .line(let speaker, let text) = element {
      XCTAssertEqual(speaker, "Guard")
      XCTAssertEqual(text, "Halt! Who goes there?")
    } else {
      XCTFail("Expected .line element")
    }
  }

  // MARK: - DialogElement Tests

  func testDialogElementLine() {
    let guard1 = Speaker("Guard")
    let element = guard1 ~ "Hello"

    if case .line(let speaker, let text) = element {
      XCTAssertEqual(speaker, "Guard")
      XCTAssertEqual(text, "Hello")
    } else {
      XCTFail("Expected .line element")
    }
  }

  func testDialogElementChoice() {
    let element = Choice("Pay 10 gold") {
      Speaker("Merchant") ~ "Thank you!"
    }

    if case .choice(let text, let condition, let content) = element {
      XCTAssertEqual(text, "Pay 10 gold")
      XCTAssertNil(condition, "Unconditional choice should have nil condition")
      XCTAssertEqual(content.count, 1)
    } else {
      XCTFail("Expected .choice element")
    }
  }

  func testDialogElementJump() {
    let element = Jump("market")

    if case .jump(let branchId) = element {
      XCTAssertEqual(branchId, "market")
    } else {
      XCTFail("Expected .jump element")
    }
  }

  func testDialogElementEmit() {
    let element = Emit("giveGold", ["amount": 100])

    if case .emit(let name, let data) = element {
      XCTAssertEqual(name, "giveGold")
      XCTAssertNotNil(data)
      XCTAssertEqual(data?["amount"] as? Int, 100)
    } else {
      XCTFail("Expected .emit element")
    }
  }

  func testDialogElementEnd() {
    let element = End

    if case .end = element {
      XCTAssertTrue(true)
    } else {
      XCTFail("Expected .end element")
    }
  }

  // MARK: - Branch and Dialog Tests

  func testBranchCreation() {
    let guard1 = Speaker("Guard")

    let branch = Branch("intro") {
      guard1 ~ "Welcome!"
      guard1 ~ "How can I help?"
    }

    XCTAssertEqual(branch.id, "intro")
    XCTAssertEqual(branch.elements.count, 2)
  }

  func testDialogCreation() {
    let guard1 = Speaker("Guard")

    let dialog = Dialog(id: "guard_dialog") {
      Branch("intro") {
        guard1 ~ "Welcome!"
      }
      Branch("farewell") {
        guard1 ~ "Goodbye!"
      }
    }

    XCTAssertEqual(dialog.id, "guard_dialog")
    XCTAssertEqual(dialog.branches.count, 2)
  }

  func testDialogBranchLookup() {
    let guard1 = Speaker("Guard")

    let dialog = Dialog {
      Branch("intro") {
        guard1 ~ "Hello"
      }
      Branch("quest") {
        guard1 ~ "I have a task"
      }
    }

    let introBranch = dialog.branch("intro")
    XCTAssertNotNil(introBranch)
    XCTAssertEqual(introBranch?.id, "intro")

    let questBranch = dialog.branch("quest")
    XCTAssertNotNil(questBranch)
    XCTAssertEqual(questBranch?.id, "quest")

    let missingBranch = dialog.branch("nonexistent")
    XCTAssertNil(missingBranch)
  }

  func testDialogFirstBranch() {
    let npc = Speaker("NPC")

    let dialog = Dialog {
      Branch("first") {
        npc ~ "First branch"
      }
      Branch("second") {
        npc ~ "Second branch"
      }
    }

    let first = dialog.firstBranch
    XCTAssertNotNil(first)
    XCTAssertEqual(first?.id, "first")
  }

  // MARK: - DialogState Tests

  func testDialogStateInitial() {
    let state = DialogState(visitCount: 1)
    XCTAssertEqual(state.visitCount, 1)
  }

  func testDialogStateFirstVisit() {
    let state = DialogState(visitCount: 1)
    XCTAssertTrue(state.isFirstVisit)

    let state2 = DialogState(visitCount: 2)
    XCTAssertFalse(state2.isFirstVisit)
  }

  func testDialogStateSubsequentVisits() {
    let state = DialogState(visitCount: 5)
    XCTAssertEqual(state.visitCount, 5)
    XCTAssertFalse(state.isFirstVisit)
  }

  // MARK: - Complex Dialog Tests

  func testComplexDialog() {
    let guard1 = Speaker("Guard")
    let merchant = Speaker("Merchant")

    let dialog = Dialog(id: "complex") {
      Branch("gate") {
        guard1 ~ "Halt!"
        Choice("I'm a traveler") {
          guard1 ~ "Proceed."
          Jump("market")
        }
        Choice("I'm here on business") {
          guard1 ~ "Show your papers."
          End
        }
      }
      Branch("market") {
        merchant ~ "Welcome to my shop!"
        Emit("openShop")
      }
    }

    XCTAssertEqual(dialog.id, "complex")
    XCTAssertEqual(dialog.branches.count, 2)

    // Check gate branch has choices
    let gateBranch = dialog.branch("gate")
    XCTAssertNotNil(gateBranch)
    XCTAssertEqual(gateBranch?.elements.count, 3) // line + 2 choices

    // Check market branch
    let marketBranch = dialog.branch("market")
    XCTAssertNotNil(marketBranch)
    XCTAssertEqual(marketBranch?.elements.count, 2) // line + emit
  }
}
