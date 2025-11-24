import SwiftGodot
import SwiftGodotBuilder

struct Chapter15Palette {
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

  // MARK: - Common StyleBox Builders

  /// Creates button styleboxes with the specified color scheme
  func buttonStyles(
    _ color: Color,
    normalAlpha: Double = 0.2,
    hoverAlpha: Double = 0.3,
    pressedAlpha: Double = 0.5
  ) -> [String: StyleBoxFlat$] {
    [
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
        .cornerRadius(4)
    ]
  }

  /// Creates button styleboxes with separate hover border color
  func buttonStyles(
    _ color: Color,
    hoverBorder: Color,
    normalAlpha: Double = 0.2,
    hoverAlpha: Double = 0.4,
    pressedAlpha: Double = 0.6
  ) -> [String: StyleBoxFlat$] {
    [
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
        .cornerRadius(4)
    ]
  }

  /// Standard gray button styles
  var grayButtonStyles: [String: StyleBoxFlat$] {
    buttonStyles(gray)
  }

  /// Standard cyan button styles
  var cyanButtonStyles: [String: StyleBoxFlat$] {
    buttonStyles(cyan)
  }

  /// Standard green button styles
  var greenButtonStyles: [String: StyleBoxFlat$] {
    buttonStyles(green)
  }

  /// Standard yellow button styles with bright hover
  var yellowButtonStyles: [String: StyleBoxFlat$] {
    buttonStyles(yellow, hoverBorder: yellowBright)
  }

  /// Standard purple button styles
  var purpleButtonStyles: [String: StyleBoxFlat$] {
    buttonStyles(purple)
  }

  /// Standard panel stylebox
  var panelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(Color(r: 0.05, g: 0.05, b: 0.1, a: 0.95))
      .borderColor(cyan)
      .borderWidth(2)
      .contentMargin(2)
      .expandMargin(4)
      .cornerRadius(8)
  }

  /// Victory panel with green glow
  var victoryPanelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(Color(r: 0.05, g: 0.15, b: 0.05, a: 0.95))
      .borderColor(green)
      .borderWidth(2)
      .contentMargin(2)
      .expandMargin(4)
      .cornerRadius(8)
  }

  /// Game over panel with red glow
  var gameOverPanelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(Color(r: 0.15, g: 0.05, b: 0.05, a: 0.95))
      .borderColor(redLight)
      .borderWidth(2)
      .contentMargin(2)
      .expandMargin(4)
      .cornerRadius(8)
  }

  /// Pause panel styling
  var pausePanelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(Color(r: 0.1, g: 0.1, b: 0.15, a: 0.98))
      .borderColor(white.withAlpha(0.5))
      .borderWidth(2)
      .expandMargin(2)
      .contentMargin(2)
      .cornerRadius(8)
  }

  /// Settings panel styling
  var settingsPanelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(Color(r: 0.08, g: 0.08, b: 0.12, a: 0.98))
      .borderColor(purple)
      .borderWidth(2)
      .expandMargin(-2)
      .cornerRadius(4)
  }

  /// Character sheet panel
  var characterPanelStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(Color(r: 0.05, g: 0.08, b: 0.12, a: 0.98))
      .borderColor(cyan)
      .borderWidth(3)
      .cornerRadius(8)
      .contentMargin(8)
  }

  /// Stat section panel (red for health)
  var healthSectionStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(red.withAlpha(0.1))
      .borderColor(red.withAlpha(0.4))
      .borderWidth(1)
      .cornerRadius(4)
      .contentMargin(4)
  }

  /// Stat section panel (yellow for inventory)
  var inventorySectionStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(yellow.withAlpha(0.1))
      .borderColor(yellow.withAlpha(0.4))
      .borderWidth(1)
      .cornerRadius(4)
      .contentMargin(4)
  }

  /// Stat section panel (cyan for weapons)
  var weaponSectionStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(cyan.withAlpha(0.1))
      .borderColor(cyan.withAlpha(0.4))
      .borderWidth(1)
      .cornerRadius(4)
      .contentMargin(4)
  }

  /// Stat section panel (green for stats)
  var statsSectionStyle: StyleBoxFlat$ {
    StyleBoxFlat$()
      .bgColor(green.withAlpha(0.1))
      .borderColor(green.withAlpha(0.4))
      .borderWidth(1)
      .cornerRadius(4)
      .contentMargin(4)
  }

  /// Enhanced cyan button styles (higher alphas for primary actions)
  var cyanButtonStylesEnhanced: [String: StyleBoxFlat$] {
    buttonStyles(cyan, normalAlpha: 0.3, hoverAlpha: 0.5, pressedAlpha: 0.7)
  }

  /// Enhanced green button styles (higher alphas for primary actions)
  var greenButtonStylesEnhanced: [String: StyleBoxFlat$] {
    buttonStyles(green, normalAlpha: 0.3, hoverAlpha: 0.5, pressedAlpha: 0.7)
  }

  /// Gray button with light gray hover
  var grayButtonStylesWithLightHover: [String: StyleBoxFlat$] {
    [
      "normal": StyleBoxFlat$()
        .bgColor(gray.withAlpha(0.2))
        .borderColor(gray)
        .borderWidth(2)
        .cornerRadius(4),
      "hover": StyleBoxFlat$()
        .bgColor(lightGray.withAlpha(0.3))
        .borderColor(lightGray)
        .borderWidth(2)
        .cornerRadius(4),
      "pressed": StyleBoxFlat$()
        .bgColor(darkGray.withAlpha(0.5))
        .borderColor(lightGray)
        .borderWidth(2)
        .cornerRadius(4)
    ]
  }
}
