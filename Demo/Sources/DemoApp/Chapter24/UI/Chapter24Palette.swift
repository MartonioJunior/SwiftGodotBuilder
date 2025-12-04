import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct Palette: Sendable {
    static let shared = Palette()

    // MARK: - UI/Font Colors

    let white = Color(code: "#FFFFFF")
    let whiteTranslucent = Color(code: "#FFFFFFE6")
    let lightGray = Color(code: "#E6E6E6")
    let gray = Color(code: "#B3B3B3")
    let darkGray = Color(code: "#999999")
    let red = Color(code: "#FF3333")
    let redLight = Color(code: "#FF4D4D")
    let yellow = Color(code: "#FFE64D")
    let yellowBright = Color(code: "#FFFF80")
    let gold = Color(code: "#FFCC00")
    let green = Color(code: "#4DFF4D")
    let greenLight = Color(code: "#80FF80")
    let cyan = Color(code: "#4DCCFF")
    let purple = Color(code: "#B366FF")

    // MARK: - Section Header Colors

    let healthHeader = Color(code: "#FF8080")
    let weaponHeader = Color(code: "#80CCFF")

    // MARK: - Common StyleBox Builders

    func buttonStyles(
      _ color: Color,
      normalAlpha: Double = 0.2,
      hoverAlpha: Double = 0.3,
      pressedAlpha: Double = 0.5,
      focusAlpha: Double = 0.4,
      withFocus: Bool = false
    ) -> [String: StyleBoxFlat$] {
      var styles: [String: StyleBoxFlat$] = [
        "normal": StyleBoxFlat$()
          .bgColor(color.withAlpha(normalAlpha))
          .borderColor(color)
          .borderWidth(2)
          .cornerRadius(4),
        "hover": StyleBoxFlat$()
          .bgColor(color.withAlpha(hoverAlpha))
          .borderColor(color)
          .borderWidth(2)
          .cornerRadius(4),
        "pressed": StyleBoxFlat$()
          .bgColor(color.withAlpha(pressedAlpha))
          .borderColor(color)
          .borderWidth(2)
          .cornerRadius(4),
      ]
      if withFocus {
        styles["focus"] = StyleBoxFlat$()
          .bgColor(color.withAlpha(focusAlpha))
          .borderColor(white)
          .borderWidth(2)
          .cornerRadius(4)
      }
      return styles
    }

    func buttonStyles(
      _ color: Color,
      hoverBorder: Color,
      normalAlpha: Double = 0.2,
      hoverAlpha: Double = 0.4,
      pressedAlpha: Double = 0.6,
      focusAlpha: Double = 0.4,
      withFocus: Bool = false
    ) -> [String: StyleBoxFlat$] {
      var styles: [String: StyleBoxFlat$] = [
        "normal": StyleBoxFlat$()
          .bgColor(color.withAlpha(normalAlpha))
          .borderColor(color)
          .borderWidth(2)
          .cornerRadius(4),
        "hover": StyleBoxFlat$()
          .bgColor(color.withAlpha(hoverAlpha))
          .borderColor(hoverBorder)
          .borderWidth(2)
          .cornerRadius(4),
        "pressed": StyleBoxFlat$()
          .bgColor(color.withAlpha(pressedAlpha))
          .borderColor(hoverBorder)
          .borderWidth(2)
          .cornerRadius(4),
      ]
      if withFocus {
        styles["focus"] = StyleBoxFlat$()
          .bgColor(color.withAlpha(focusAlpha))
          .borderColor(white)
          .borderWidth(2)
          .cornerRadius(4)
      }
      return styles
    }

    func overlayPanel(
      bg: Color,
      border: Color,
      borderWidth: Int32 = 2,
      cornerRadius: Int32 = 8,
      contentMargin: Double = 2,
      expandMargin: Double = 4
    ) -> StyleBoxFlat$ {
      StyleBoxFlat$()
        .bgColor(bg)
        .borderColor(border)
        .borderWidth(borderWidth)
        .contentMargin(contentMargin)
        .expandMargin(expandMargin)
        .cornerRadius(cornerRadius)
    }

    // Common dark backgrounds
    let panelBgDark = Color(r: 0.05, g: 0.05, b: 0.1, a: 0.95)
    let panelBgGreen = Color(r: 0.05, g: 0.15, b: 0.05, a: 0.95)
    let panelBgRed = Color(r: 0.15, g: 0.05, b: 0.05, a: 0.95)
    let panelBgNeutral = Color(r: 0.1, g: 0.1, b: 0.15, a: 0.98)
    let panelBgSettings = Color(r: 0.08, g: 0.08, b: 0.12, a: 0.98)
    let panelBgCharacter = Color(r: 0.05, g: 0.08, b: 0.12, a: 0.98)

    var panelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgDark, border: cyan) }
    var victoryPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgGreen, border: green) }
    var gameOverPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgRed, border: redLight) }
    var pausePanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgNeutral, border: white.withAlpha(0.5), expandMargin: 2) }
    var settingsPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgSettings, border: purple, cornerRadius: 4, expandMargin: -2) }
    var characterPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgCharacter, border: cyan, borderWidth: 3, contentMargin: 8) }

    func sectionStyle(_ color: Color) -> StyleBoxFlat$ {
      StyleBoxFlat$()
        .bgColor(color.withAlpha(0.1))
        .borderColor(color.withAlpha(0.4))
        .borderWidth(1)
        .cornerRadius(4)
        .contentMargin(4)
    }

    var healthSectionStyle: StyleBoxFlat$ { sectionStyle(red) }
    var inventorySectionStyle: StyleBoxFlat$ { sectionStyle(yellow) }
    var weaponSectionStyle: StyleBoxFlat$ { sectionStyle(cyan) }
    var statsSectionStyle: StyleBoxFlat$ { sectionStyle(green) }

    var cyanButtonStylesWithFocus: [String: StyleBoxFlat$] {
      buttonStyles(cyan, withFocus: true)
    }

    var grayButtonStylesWithFocus: [String: StyleBoxFlat$] {
      buttonStyles(gray, withFocus: true)
    }

    var yellowButtonStylesWithFocus: [String: StyleBoxFlat$] {
      buttonStyles(yellow, hoverBorder: yellowBright, withFocus: true)
    }

    var purpleButtonStylesWithFocus: [String: StyleBoxFlat$] {
      buttonStyles(purple, withFocus: true)
    }

    var greenButtonStylesWithFocus: [String: StyleBoxFlat$] {
      buttonStyles(green, withFocus: true)
    }

  }
}
