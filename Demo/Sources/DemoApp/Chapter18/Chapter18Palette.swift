import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct Palette {
    // MARK: - Player Colors

    let playerBlue = Color(code: "#4D80E6")
    let playerWhiteFlash = Color(code: "#FFFFFF")
    let playerDash = Color(code: "#FFB34D")
    let playerDoubleJump = Color(code: "#4DE6FF")
    let playerDashTrail = Color(code: "#FFFFFFCC")

    // MARK: - Enemy Colors

    let enemyRed = Color(code: "#E64D4D")
    let enemyRedDark = Color(code: "#993333")
    let enemyPurple = Color(code: "#CC4DE6")
    let enemyPurpleDark = Color(code: "#9933B3")
    let enemyProjectile = Color(code: "#CC3333")

    // MARK: - Item Colors

    let coin = Color(code: "#FF991A")
    let key = Color(code: "#FFE633")
    let keyLock = Color(code: "#E6CC33")
    let goal = Color(code: "#33CC33")
    let ammo = Color(code: "#4DCCFF")
    let healthDrop = Color(code: "#FF4D80")
    let projectile = Color(code: "#4DFF66")

    // MARK: - Door Colors

    let doorUnlocked = Color(code: "#33CC3380")
    let doorLocked = Color(code: "#994D1A")

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

    // MARK: - Particle Colors

    let particleGray = Color(code: "#CCCCCC99")
    let particleDarkGray = Color(code: "#B3B3B3B3")
    let particleBlue = Color(code: "#4D80E666")
    let particleRed = Color(code: "#FF4D4DCC")
    let particleOrange = Color(code: "#FF8000B3")
    let particleYellow = Color(code: "#FFFF66E6")
    let particleYellowAlt = Color(code: "#FFE64DCC")

    // MARK: - Enemy Spawner Colors

    let enemySpawnerPurple = Color(code: "#8080FF")

    // MARK: - Boss Colors

    let bossRed = Color(code: "#CC2222")
    let bossOrange = Color(code: "#FF6600")
    let bossPurple = Color(code: "#9933FF")

    // MARK: - Checkpoint Colors

    let checkpointInactive = Color(code: "#808080")
    let checkpointActive = Color(code: "#4DFF4D")
    let checkpointHighlight = Color(code: "#80FF80")
    let checkpointPole = Color(code: "#666666")

    // MARK: - Hazard Colors

    let spikes = Color(code: "#808080")
    let spikesTip = Color(code: "#B3B3B3")
    let lava = Color(code: "#FF4400")
    let lavaGlow = Color(code: "#FF6600")
    let water = Color(code: "#3366CC")
    let waterSurface = Color(code: "#4488FF")
    let crusher = Color(code: "#666666")
    let crusherDark = Color(code: "#444444")
    let movingPlatform = Color(code: "#668844")
    let fallingPlatform = Color(code: "#886644")
    let fallingPlatformWarning = Color(code: "#CC8844")

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

    var grayButtonStyles: [String: StyleBoxFlat$] { buttonStyles(gray) }
    var cyanButtonStyles: [String: StyleBoxFlat$] { buttonStyles(cyan) }
    var greenButtonStyles: [String: StyleBoxFlat$] { buttonStyles(green) }
    var yellowButtonStyles: [String: StyleBoxFlat$] { buttonStyles(yellow, hoverBorder: yellowBright) }
    var purpleButtonStyles: [String: StyleBoxFlat$] { buttonStyles(purple) }

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

    var cyanButtonStylesEnhanced: [String: StyleBoxFlat$] {
      buttonStyles(cyan, normalAlpha: 0.3, hoverAlpha: 0.5, pressedAlpha: 0.7)
    }

    var greenButtonStylesEnhanced: [String: StyleBoxFlat$] {
      buttonStyles(green, normalAlpha: 0.3, hoverAlpha: 0.5, pressedAlpha: 0.7)
    }

    var grayButtonStylesWithLightHover: [String: StyleBoxFlat$] {
      buttonStyles(gray, hoverBorder: lightGray)
    }

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

    var bossHealthBarStyle: StyleBoxFlat$ {
      StyleBoxFlat$()
        .bgColor(Color(r: 0.1, g: 0.1, b: 0.1, a: 0.9))
        .borderColor(bossRed)
        .borderWidth(2)
        .cornerRadius(2)
    }
  }
}
