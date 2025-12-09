import Foundation
import SwiftGodot

public struct Palette: Sendable {
  public static let shared = Palette()

  public init() {}

  // MARK: - UI/Font Colors

  public let white = Color(code: "#FFFFFF")
  public let whiteTranslucent = Color(code: "#FFFFFFE6")
  public let lightGray = Color(code: "#E6E6E6")
  public let gray = Color(code: "#B3B3B3")
  public let darkGray = Color(code: "#999999")
  public let red = Color(code: "#FF3333")
  public let redLight = Color(code: "#FF4D4D")
  public let yellow = Color(code: "#FFE64D")
  public let yellowBright = Color(code: "#FFFF80")
  public let gold = Color(code: "#FFCC00")
  public let green = Color(code: "#4DFF4D")
  public let greenLight = Color(code: "#80FF80")
  public let cyan = Color(code: "#4DCCFF")
  public let purple = Color(code: "#B366FF")

  // MARK: - Section Header Colors

  public let healthHeader = Color(code: "#FF8080")
  public let weaponHeader = Color(code: "#80CCFF")

  // MARK: - Common StyleBox Builders

  public func buttonStyles(
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

  public func buttonStyles(
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

  public func overlayPanel(
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
  public let panelBgDark = Color(r: 0.05, g: 0.05, b: 0.1, a: 0.95)
  public let panelBgGreen = Color(r: 0.05, g: 0.15, b: 0.05, a: 0.95)
  public let panelBgRed = Color(r: 0.15, g: 0.05, b: 0.05, a: 0.95)
  public let panelBgNeutral = Color(r: 0.1, g: 0.1, b: 0.15, a: 0.98)
  public let panelBgSettings = Color(r: 0.08, g: 0.08, b: 0.12, a: 0.98)

  public var panelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgDark, border: cyan) }
  public var victoryPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgGreen, border: green) }
  public var gameOverPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgRed, border: redLight) }
  public var pausePanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgNeutral, border: white.withAlpha(0.5), expandMargin: 2) }
  public var settingsPanelStyle: StyleBoxFlat$ { overlayPanel(bg: panelBgSettings, border: purple, cornerRadius: 4, expandMargin: -2) }

  public var cyanButtonStylesWithFocus: [String: StyleBoxFlat$] {
    buttonStyles(cyan, withFocus: true)
  }

  public var grayButtonStylesWithFocus: [String: StyleBoxFlat$] {
    buttonStyles(gray, withFocus: true)
  }

  public var yellowButtonStylesWithFocus: [String: StyleBoxFlat$] {
    buttonStyles(yellow, hoverBorder: yellowBright, withFocus: true)
  }

  public var purpleButtonStylesWithFocus: [String: StyleBoxFlat$] {
    buttonStyles(purple, withFocus: true)
  }

  public var greenButtonStylesWithFocus: [String: StyleBoxFlat$] {
    buttonStyles(green, withFocus: true)
  }
}
