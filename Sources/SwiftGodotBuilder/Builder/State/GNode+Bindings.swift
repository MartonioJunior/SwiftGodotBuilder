import SwiftGodot
@preconcurrency import Observation

// MARK: - Two-way binding for Range controls

/// Two-way binding helpers for Range controls (Slider, ScrollBar, SpinBox)
public extension GNode where T: Range {
  /// Creates a two-way binding between a Range control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial value of the control from the observable property
  /// - Updates the observable property whenever the control's value changes via the `valueChanged` signal
  ///
  /// Use this for range input controls (Slider, ScrollBar, SpinBox) with ObservableState to automatically sync their values.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// HSlider$()
  ///   .min(0)
  ///   .max(1)
  ///   .value(settings.masterVolume) // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func value<O: AnyObject & Observable>(_ property: ObservableProperty<O, Double>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.value = property.observableState.object[keyPath: property.keyPath]

      // Listen for range control changes and update the observable
      _ = node.valueChanged.connect { [property] newValue in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Double> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = newValue
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

public extension GNode where T: Slider {
  /// Creates a two-way binding between a Slider control and a GState.
  /// Creates a two-way binding between a Slider control and a GState.
  ///
  /// This method:
  /// - Sets the initial value of the control from the state
  /// - Updates the state whenever the control's value changes via the `valueChanged` signal
  ///
  /// Use this for range input controls to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var volume: Double = 0.5
  ///
  /// Slider$()
  ///   .min(0)
  ///   .max(1)
  ///   .value($volume) // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func value(_ state: GState<Double>) -> Self {
    var s = self
    s.ops.append { node in
      node.value = state.wrappedValue
      _ = node.valueChanged.connect { newValue in
        state.wrappedValue = newValue
      }
      state.observe { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

/// Two-way binding helpers for ScrollBar controls
public extension GNode where T: ScrollBar {
  /// Creates a two-way binding between a ScrollBar control and a GState.
  ///
  /// This method:
  /// - Sets the initial value of the control from the state
  /// - Updates the state whenever the control's value changes via the `valueChanged` signal
  ///
  /// Use this for scroll bar controls to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var scrollPosition: Double = 0.0
  ///
  /// ScrollBar$()
  ///   .min(0)
  ///   .max(1)
  ///   .value($scrollPosition) // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func value(_ state: GState<Double>) -> Self {
    var s = self
    s.ops.append { node in
      node.value = state.wrappedValue
      _ = node.valueChanged.connect { newValue in
        state.wrappedValue = newValue
      }
      state.observe { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

/// Two-way binding helpers for SpinBox controls
public extension GNode where T: SpinBox {
  /// Creates a two-way binding between a SpinBox control and a GState.
  /// This method:
  /// - Sets the initial value of the control from the state
  /// - Updates the state whenever the control's value changes via the `valueChanged` signal
  ///
  /// Use this for spin box controls to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var spinValue: Double = 0.0
  ///
  /// SpinBox$()
  ///   .min(0)
  ///   .max(100)
  ///   .value($spinValue) // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func value(_ state: GState<Double>) -> Self {
    var s = self
    s.ops.append { node in
      node.value = state.wrappedValue
      _ = node.valueChanged.connect { newValue in
        state.wrappedValue = newValue
      }
      state.observe { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for LineEdit

/// Two-way binding helpers for LineEdit controls
public extension GNode where T: LineEdit {
  /// Creates a two-way binding between a LineEdit control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial text of the control from the observable property
  /// - Updates the observable property whenever the control's text changes via the `textChanged` signal
  ///
  /// Use this for text input fields with ObservableState to automatically sync their values.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// LineEdit$()
  ///   .placeholderText("Enter username")
  ///   .text(settings.username)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func text<O: AnyObject & Observable>(_ property: ObservableProperty<O, String>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.text = property.observableState.object[keyPath: property.keyPath]

      // Listen for text changes and update the observable
      _ = node.textChanged.connect { [property] newText in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, String> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = newText
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        // Only update if the text actually changed to avoid resetting cursor
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }

  /// Creates a two-way binding between a LineEdit control and a GState.
  ///
  /// This method:
  /// - Sets the initial text of the control from the state
  /// - Updates the state whenever the control's text changes via the `textChanged` signal
  ///
  /// Use this for text input fields to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var username: String = ""
  ///
  /// LineEdit$()
  ///   .placeholderText("Enter username")
  ///   .text($username)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func text(_ state: GState<String>) -> Self {
    var s = self
    s.ops.append { node in
      node.text = state.wrappedValue
      _ = node.textChanged.connect { newText in
        state.wrappedValue = newText
      }
      state.observe { newValue in
        // Only update if the text actually changed to avoid resetting cursor
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for TextEdit

/// Two-way binding helpers for TextEdit controls
public extension GNode where T: TextEdit {
  /// Creates a two-way binding between a TextEdit control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial text of the control from the observable property
  /// - Updates the observable property whenever the control's text changes via the `textChanged` signal
  ///
  /// Use this for multi-line text input fields with ObservableState to automatically sync their values.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// TextEdit$()
  ///   .text(settings.notes)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func text<O: AnyObject & Observable>(_ property: ObservableProperty<O, String>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.text = property.observableState.object[keyPath: property.keyPath]

      // Listen for text changes and update the observable
      _ = node.textChanged.connect { [property] in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, String> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = node.text
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        // Only update if the text actually changed to avoid resetting cursor
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }

  /// Creates a two-way binding between a TextEdit control and a GState.
  ///
  /// This method:
  /// - Sets the initial text of the control from the state
  /// - Updates the state whenever the control's text changes via the `textChanged` signal
  ///
  /// Use this for multi-line text input fields to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var notes: String = ""
  ///
  /// TextEdit$()
  ///   .text($notes)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func text(_ state: GState<String>) -> Self {
    var s = self
    s.ops.append { node in
      node.text = state.wrappedValue
      _ = node.textChanged.connect {
        state.wrappedValue = node.text
      }
      state.observe { newValue in
        // Only update if the text actually changed to avoid resetting cursor
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for CodeEdit

/// Two-way binding helpers for CodeEdit controls
public extension GNode where T: CodeEdit {
  /// Creates a two-way binding between a CodeEdit control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial text of the control from the observable property
  /// - Updates the observable property whenever the control's text changes via the `textChanged` signal
  ///
  /// Use this for code editor fields with ObservableState to automatically sync their values.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// CodeEdit$()
  ///   .text(settings.code)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func text<O: AnyObject & Observable>(_ property: ObservableProperty<O, String>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.text = property.observableState.object[keyPath: property.keyPath]

      // Listen for text changes and update the observable
      _ = node.textChanged.connect { [property] in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, String> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = node.text
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        // Only update if the text actually changed to avoid resetting cursor
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }

  /// Creates a two-way binding between a CodeEdit control and a GState.
  ///
  /// This method:
  /// - Sets the initial text of the control from the state
  /// - Updates the state whenever the control's text changes via the `textChanged` signal
  ///
  /// Use this for code editor fields to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var code: String = ""
  ///
  /// CodeEdit$()
  ///   .text($code)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func text(_ state: GState<String>) -> Self {
    var s = self
    s.ops.append { node in
      node.text = state.wrappedValue
      _ = node.textChanged.connect {
        state.wrappedValue = node.text
      }
      state.observe { newValue in
        // Only update if the text actually changed to avoid resetting cursor
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for BaseButton

/// Two-way binding helpers for BaseButton controls (CheckBox, CheckButton, Button with toggle mode)
public extension GNode where T: BaseButton {
  /// Creates a two-way binding between a BaseButton control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial button pressed state from the observable property
  /// - Updates the observable property whenever the button's pressed state changes via the `toggled` signal
  ///
  /// Use this for checkboxes, check buttons, and toggle buttons with ObservableState.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// CheckButton$()
  ///   .pressed(settings.fullscreen)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func pressed<O: AnyObject & Observable>(_ property: ObservableProperty<O, Bool>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.buttonPressed = property.observableState.object[keyPath: property.keyPath]

      // Listen for button changes and update the observable
      _ = node.toggled.connect { [property] pressed in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Bool> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = pressed
        }
      }

      // Listen for observable changes and update the button
      property.observableState.observe(property.keyPath) { newValue in
        node.buttonPressed = newValue
      }
    }
    return s
  }

  /// Creates a two-way binding between a BaseButton control and a GState.
  ///
  /// This method:
  /// - Sets the initial button pressed state from the state
  /// - Updates the state whenever the button's pressed state changes via the `toggled` signal
  ///
  /// Use this for checkboxes, check buttons, and toggle buttons to automatically sync their values with your state.
  ///
  /// ```swift
  /// @State var isEnabled: Bool = false
  ///
  /// CheckBox$()
  ///   .text("Enable feature")
  ///   .pressed($isEnabled)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func pressed(_ state: GState<Bool>) -> Self {
    var s = self
    s.ops.append { node in
      node.buttonPressed = state.wrappedValue
      _ = node.toggled.connect { pressed in
        state.wrappedValue = pressed
      }
      state.observe { newValue in
        node.buttonPressed = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for OptionButton

/// Two-way binding helpers for OptionButton controls
public extension GNode where T: OptionButton {
  /// Creates a two-way binding between an OptionButton control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial selected index from the observable property
  /// - Updates the observable property whenever the selection changes via the `itemSelected` signal
  ///
  /// Use this for dropdown menus with ObservableState to automatically sync their selected index.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// OptionButton$()
  ///   .selected(settings.selectedOption)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func selected<O: AnyObject & Observable>(_ property: ObservableProperty<O, Int>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.select(idx: Int32(property.observableState.object[keyPath: property.keyPath]))

      // Listen for selection changes and update the observable
      _ = node.itemSelected.connect { [property] index in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Int> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = Int(index)
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        node.select(idx: Int32(newValue))
      }
    }
    return s
  }

  /// Creates a two-way binding between an OptionButton control and a GState.
  ///
  /// This method:
  /// - Sets the initial selected index from the state
  /// - Updates the state whenever the selection changes via the `itemSelected` signal
  ///
  /// Use this for dropdown menus to automatically sync their selected index with your state.
  ///
  /// ```swift
  /// @State var selectedOption: Int = 0
  ///
  /// OptionButton$()
  ///   .selected($selectedOption)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func selected(_ state: GState<Int>) -> Self {
    var s = self
    // Set initial value
    s.ops.append { node in
      node.select(idx: Int32(state.wrappedValue))
      // Listen for changes and update state
      _ = node.itemSelected.connect { index in
        state.wrappedValue = Int(index)
      }
      state.observe { newValue in
        node.select(idx: Int32(newValue))
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ItemList

/// Two-way binding helpers for ItemList controls
public extension GNode where T: ItemList {
  /// Creates a two-way binding between an ItemList control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial selected index from the observable property (use -1 for no selection)
  /// - Updates the observable property whenever the selection changes via the `itemSelected` signal
  ///
  /// Use this for list selections with ObservableState to automatically sync their selected index.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// ItemList$()
  ///   .selected(settings.selectedItem)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func selected<O: AnyObject & Observable>(_ property: ObservableProperty<O, Int>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      let value = property.observableState.object[keyPath: property.keyPath]
      if value >= 0 {
        node.select(idx: Int32(value))
      } else {
        node.deselectAll()
      }

      // Listen for selection changes and update the observable
      _ = node.itemSelected.connect { [property] index in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Int> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = Int(index)
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        if newValue >= 0 {
          node.select(idx: Int32(newValue))
        } else {
          node.deselectAll()
        }
      }
    }
    return s
  }

  /// Creates a two-way binding between an ItemList control and a GState.
  ///
  /// This method:
  /// - Sets the initial selected index from the state (use -1 for no selection)
  /// - Updates the state whenever the selection changes via the `itemSelected` signal
  ///
  /// Use this for list selections to automatically sync their selected index with your state.
  ///
  /// ```swift
  /// @State var selectedItem: Int = -1
  ///
  /// ItemList$()
  ///   .selected($selectedItem)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func selected(_ state: GState<Int>) -> Self {
    var s = self
    s.ops.append { node in
      let value = state.wrappedValue
      if value >= 0 {
        node.select(idx: Int32(value))
      } else {
        node.deselectAll()
      }
      _ = node.itemSelected.connect { index in
        state.wrappedValue = Int(index)
      }
      state.observe { newValue in
        if newValue >= 0 {
          node.select(idx: Int32(newValue))
        } else {
          node.deselectAll()
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for TabBar

/// Two-way binding helpers for TabBar controls
public extension GNode where T: TabBar {
  /// Creates a two-way binding between a TabBar control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial current tab from the observable property
  /// - Updates the observable property whenever the tab changes via the `tabSelected` signal
  ///
  /// Use this for tab bars with ObservableState to automatically sync their current tab.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// TabBar$()
  ///   .currentTab(settings.currentTab)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func currentTab<O: AnyObject & Observable>(_ property: ObservableProperty<O, Int>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.currentTab = Int32(property.observableState.object[keyPath: property.keyPath])

      // Listen for tab changes and update the observable
      _ = node.tabSelected.connect { [property] tab in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Int> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = Int(tab)
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        node.currentTab = Int32(newValue)
      }
    }
    return s
  }

  /// Creates a two-way binding between a TabBar control and a GState.
  ///
  /// This method:
  /// - Sets the initial current tab from the state
  /// - Updates the state whenever the tab changes via the `tabSelected` signal
  ///
  /// Use this for tab bars to automatically sync their current tab with your state.
  ///
  /// ```swift
  /// @State var currentTab: Int = 0
  ///
  /// TabBar$()
  ///   .currentTab($currentTab)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func currentTab(_ state: GState<Int>) -> Self {
    var s = self
    s.ops.append { node in
      node.currentTab = Int32(state.wrappedValue)
      _ = node.tabSelected.connect { tab in
        state.wrappedValue = Int(tab)
      }
      state.observe { newValue in
        node.currentTab = Int32(newValue)
      }
    }
    return s
  }
}

// MARK: - Two-way binding for TabContainer

/// Two-way binding helpers for TabContainer controls
public extension GNode where T: TabContainer {
  /// Creates a two-way binding between a TabContainer control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial current tab from the observable property
  /// - Updates the observable property whenever the tab changes via the `tabSelected` signal
  ///
  /// Use this for tab containers with ObservableState to automatically sync their current tab.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// TabContainer$()
  ///   .currentTab(settings.currentTab)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func currentTab<O: AnyObject & Observable>(_ property: ObservableProperty<O, Int>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.currentTab = Int32(property.observableState.object[keyPath: property.keyPath])

      // Listen for tab changes and update the observable
      _ = node.tabSelected.connect { [property] tab in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Int> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = Int(tab)
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        node.currentTab = Int32(newValue)
      }
    }
    return s
  }

  /// Creates a two-way binding between a TabContainer control and a GState.
  ///
  /// This method:
  /// - Sets the initial current tab from the state
  /// - Updates the state whenever the tab changes via the `tabSelected` signal
  ///
  /// Use this for tab containers to automatically sync their current tab with your state.
  ///
  /// ```swift
  /// @State var currentTab: Int = 0
  ///
  /// TabContainer$()
  ///   .currentTab($currentTab)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func currentTab(_ state: GState<Int>) -> Self {
    var s = self
    s.ops.append { node in
      node.currentTab = Int32(state.wrappedValue)
      _ = node.tabSelected.connect { tab in
        state.wrappedValue = Int(tab)
      }
      state.observe { newValue in
        node.currentTab = Int32(newValue)
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ColorPicker

/// Two-way binding helpers for ColorPicker controls
public extension GNode where T: ColorPicker {
  /// Creates a two-way binding between a ColorPicker control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial color from the observable property
  /// - Updates the observable property whenever the color changes via the `colorChanged` signal
  ///
  /// Use this for color pickers with ObservableState to automatically sync their color.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// ColorPicker$()
  ///   .color(settings.selectedColor)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func color<O: AnyObject & Observable>(_ property: ObservableProperty<O, Color>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.color = property.observableState.object[keyPath: property.keyPath]

      // Listen for color changes and update the observable
      _ = node.colorChanged.connect { [property] newColor in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Color> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = newColor
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        node.color = newValue
      }
    }
    return s
  }

  /// Creates a two-way binding between a ColorPicker control and a GState.
  ///
  /// This method:
  /// - Sets the initial color from the state
  /// - Updates the state whenever the color changes via the `colorChanged` signal
  ///
  /// Use this for color pickers to automatically sync their color with your state.
  ///
  /// ```swift
  /// @State var selectedColor: Color = .white
  ///
  /// ColorPicker$()
  ///   .color($selectedColor)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func color(_ state: GState<Color>) -> Self {
    var s = self
    s.ops.append { node in
      node.color = state.wrappedValue
      _ = node.colorChanged.connect { newColor in
        state.wrappedValue = newColor
      }
      state.observe { newValue in
        node.color = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ColorPickerButton

/// Two-way binding helpers for ColorPickerButton controls
public extension GNode where T: ColorPickerButton {
  /// Creates a two-way binding between a ColorPickerButton control and an ObservableProperty.
  ///
  /// This method:
  /// - Sets the initial color from the observable property
  /// - Updates the observable property whenever the color changes via the `colorChanged` signal
  ///
  /// Use this for color picker buttons with ObservableState to automatically sync their color.
  ///
  /// ```swift
  /// @ObservableState var settings = GameSettings()
  ///
  /// ColorPickerButton$()
  ///   .color(settings.selectedColor)  // Two-way binding
  /// ```
  ///
  /// - Parameter property: The observable property to bind to
  /// - Returns: The modified `GNode` with the binding established
  func color<O: AnyObject & Observable>(_ property: ObservableProperty<O, Color>) -> Self {
    var s = self
    s.ops.append { [property] node in
      // Set initial value
      node.color = property.observableState.object[keyPath: property.keyPath]

      // Listen for color changes and update the observable
      _ = node.colorChanged.connect { [property] newColor in
        // Mutate the observable object (classes are reference types)
        if let writableKeyPath = property.keyPath as? WritableKeyPath<O, Color> {
          var mutableObject = property.observableState.object
          mutableObject[keyPath: writableKeyPath] = newColor
        }
      }

      // Listen for observable changes and update the control
      property.observableState.observe(property.keyPath) { newValue in
        node.color = newValue
      }
    }
    return s
  }

  /// Creates a two-way binding between a ColorPickerButton control and a GState.
  ///
  /// This method:
  /// - Sets the initial color from the state
  /// - Updates the state whenever the color changes via the `colorChanged` signal
  ///
  /// Use this for color picker buttons to automatically sync their color with your state.
  ///
  /// ```swift
  /// @State var selectedColor: Color = .white
  ///
  /// ColorPickerButton$()
  ///   .color($selectedColor)  // Two-way binding
  /// ```
  ///
  /// - Parameter state: The state variable to bind to (use $ prefix)
  /// - Returns: The modified `GNode` with the binding established
  func color(_ state: GState<Color>) -> Self {
    var s = self
    s.ops.append { node in
      node.color = state.wrappedValue
      _ = node.colorChanged.connect { newColor in
        state.wrappedValue = newColor
      }
      state.observe { newValue in
        node.color = newValue
      }
    }
    return s
  }
}
