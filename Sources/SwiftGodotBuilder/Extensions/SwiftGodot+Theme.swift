import Foundation
import SwiftGodot

/// Theme dictionary extensions.
///
/// These extensions provide convenient methods for building themes from dictionaries:
///
/// ### Example: Creating a theme from a dictionary (camelCase or snake_case)
/// ```swift
/// let myTheme = Theme.build([
///   "Button": [
///     "colors": ["fontColor": Color.white],       // camelCase keys automatically converted
///     "constants": ["outlineSize": 2],
///     "fontSizes": ["fontSize": 16]               // Both outer and inner keys support camelCase
///   ],
///   "Label": [
///     "colors": ["font_color": Color.white],      // snake_case also works
///     "font_sizes": ["font_size": 14]
///   ]
/// ])
/// ```
public extension Theme {
  /// Creates a theme from a dictionary structure.
  ///
  /// The dictionary structure supports both camelCase and snake_case keys.
  /// All keys (both outer category keys and inner property names) are automatically
  /// converted from camelCase to snake_case when applying to Godot's theme system.
  ///
  /// ```
  /// [
  ///   "ControlType": [
  ///     "colors": ["fontColor" or "font_color": Color],
  ///     "constants": ["outlineSize" or "outline_size": Int],
  ///     "fonts": ["fontName" or "font_name": Font],
  ///     "fontSizes" or "font_sizes": ["fontSize" or "font_size": Int],
  ///     "icons": ["iconName" or "icon_name": Texture2D],
  ///     "styleBoxes" or "styleboxes": ["normalStyle" or "normal_style": StyleBox]
  ///   ]
  /// ]
  /// ```
  ///
  /// - Parameter dict: Dictionary mapping control types to their theme properties
  convenience init(_ dict: [String: [String: Any]]) {
    self.init()
    applyDict(dict)
  }

  /// Applies theme properties from a dictionary structure.
  ///
  /// - Parameter dict: Dictionary mapping control types to their theme properties
  func applyDict(_ dict: [String: [String: Any]]) {
    for (controlType, properties) in dict {
      let typeName = StringName(controlType)

      // Apply colors
      if let colors = (properties["colors"] ?? properties["colors".fromCamelCase()]) as? [String: Color] {
        for (name, value) in colors {
          setColor(name: StringName(name.fromCamelCase()), themeType: typeName, color: value)
        }
      }

      // Apply constants
      if let constants = (properties["constants"] ?? properties["constants".fromCamelCase()]) as? [String: Int] {
        for (name, value) in constants {
          setConstant(name: StringName(name.fromCamelCase()), themeType: typeName, constant: Int32(value))
        }
      }

      // Apply fonts
      if let fonts = (properties["fonts"] ?? properties["fonts".fromCamelCase()]) as? [String: Font] {
        for (name, value) in fonts {
          setFont(name: StringName(name.fromCamelCase()), themeType: typeName, font: value)
        }
      }

      // Apply font sizes
      if let fontSizes = (properties["font_sizes"] ?? properties["fontSizes"]) as? [String: Int] {
        for (name, value) in fontSizes {
          setFontSize(name: StringName(name.fromCamelCase()), themeType: typeName, fontSize: Int32(value))
        }
      }

      // Apply icons
      if let icons = (properties["icons"] ?? properties["icons".fromCamelCase()]) as? [String: Texture2D] {
        for (name, value) in icons {
          setIcon(name: StringName(name.fromCamelCase()), themeType: typeName, texture: value)
        }
      }

      // Apply styleboxes
      if let styleBoxes = (properties["styleboxes"] ?? properties["styleBoxes"]) as? [String: StyleBox] {
        for (name, value) in styleBoxes {
          setStylebox(name: StringName(name.fromCamelCase()), themeType: typeName, texture: value)
        }
      }
    }
  }

  /// Converts a camelCase string to snake_case.
  private func camelToSnake(_ string: String) -> String {
    let pattern = "([a-z0-9])([A-Z])"
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(string.startIndex..., in: string)
    return regex.stringByReplacingMatches(
      in: string,
      range: range,
      withTemplate: "$1_$2"
    ).lowercased()
  }
}

private extension String {
  /// Returns the snake_case version of this camelCase string.
  func fromCamelCase() -> String {
    let pattern = "([a-z0-9])([A-Z])"
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(startIndex..., in: self)
    return regex.stringByReplacingMatches(
      in: self,
      range: range,
      withTemplate: "$1_$2"
    ).lowercased()
  }
}

// MARK: - GNode theme modifier

public extension GNode where T: Control {
  /// Applies a theme to this control.
  ///
  /// - Parameter theme: The Theme to apply
  func theme(_ theme: Theme) -> Self {
    var s = self
    s.ops.append { $0.theme = theme }
    return s
  }

  /// Applies a static StyleBox theme override.
  ///
  /// ```swift
  /// Button$()
  ///   .theme("normal", myStyleBox)
  /// ```
  func theme(_ name: String, _ styleBox: StyleBox) -> Self {
    var s = self
    s.ops.append { node in
      node.addThemeStyleboxOverride(name: StringName(name), stylebox: styleBox)
    }
    return s
  }

  /// Applies a static StyleBoxBuilder theme override.
  ///
  /// ```swift
  /// Button$()
  ///   .theme("normal", StyleBoxFlat$().bgColor(.gray))
  /// ```
  func theme<S: StyleBox>(_ name: String, _ builder: StyleBoxBuilder<S>) -> Self {
    theme(name, builder.toObject())
  }

  /// Applies a reactive StyleBox theme override.
  ///
  /// The StyleBox will automatically update when the GState value changes.
  ///
  /// ```swift
  /// Button$()
  ///   .theme("normal", $normalStyleBox)
  /// ```
  func theme(_ name: String, _ state: GState<StyleBox>) -> Self {
    var s = self
    s.ops.append { [state] node in
      state.observe(owner: node) { styleBox in
        node.addThemeStyleboxOverride(name: StringName(name), stylebox: styleBox)
      }
    }
    return s
  }

  /// Applies a reactive StyleBox theme override (generic for StyleBox subclasses).
  ///
  /// The StyleBox will automatically update when the GState value changes.
  ///
  /// ```swift
  /// Button$()
  ///   .theme("normal", normalStyleBoxState)
  /// ```
  func theme<S: StyleBox>(_ name: String, _ state: GState<S>) -> Self {
    var s = self
    s.ops.append { [state] node in
      state.observe(owner: node) { styleBox in
        node.addThemeStyleboxOverride(name: StringName(name), stylebox: styleBox)
      }
    }
    return s
  }

  /// Applies theme properties using a flat dictionary.
  ///
  /// ```swift
  /// Label$()
  ///   .theme([
  ///     "fontSize": 32,
  ///     "fontColor": Color.white
  ///   ])
  /// ```
  ///
  /// Auto-categorization:
  /// - `*Color` → colors
  /// - `*Size` or `fontSize` → fontSizes
  /// - Numeric values → constants
  /// - Font values → fonts
  /// - Texture2D values → icons
  /// - StyleBox values → styleboxes
  ///
  /// - Parameter _: Dictionary of property names to values
  func theme(_ flat: [String: Any]) -> Self {
    var categorized: [String: Any] = [:]

    for (key, value) in flat {
      let category: String

      // Determine category based on key name and value type
      if key.hasSuffix("Color") || key == "fontColor" {
        category = "colors"
      } else if key.hasSuffix("Size") || key == "fontSize" {
        category = "fontSizes"
      } else if key.hasSuffix("Font") || value is Font {
        category = "fonts"
      } else if value is Texture2D {
        category = "icons"
      } else if value is StyleBox {
        category = "styleboxes"
      } else if value is Int || value is Int32 {
        category = "constants"
      } else {
        // Default to constants for unknown types
        category = "constants"
      }

      if categorized[category] == nil {
        categorized[category] = [String: Any]()
      }
      var catDict = categorized[category] as! [String: Any]
      catDict[key] = value
      categorized[category] = catDict
    }

    let controlType = String(describing: T.self)
    return theme(Theme([controlType: categorized]))
  }
}
