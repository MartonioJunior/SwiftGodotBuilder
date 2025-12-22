import SwiftGodot

// MARK: - Two-way binding for Slider

public extension GNode where T: Slider {
  /// Creates a two-way binding between a Slider control and a GState.
  ///
  /// This method:
  /// - Sets the initial value of the control from the state
  /// - Updates the state whenever the control's value changes via the `valueChanged` signal
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
      state.observe(owner: node) { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ScrollBar

public extension GNode where T: ScrollBar {
  /// Creates a two-way binding between a ScrollBar control and a GState.
  ///
  /// ```swift
  /// @State var scrollPosition: Double = 0.0
  ///
  /// ScrollBar$()
  ///   .min(0)
  ///   .max(1)
  ///   .value($scrollPosition) // Two-way binding
  /// ```
  func value(_ state: GState<Double>) -> Self {
    var s = self
    s.ops.append { node in
      node.value = state.wrappedValue
      _ = node.valueChanged.connect { newValue in
        state.wrappedValue = newValue
      }
      state.observe(owner: node) { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for SpinBox

public extension GNode where T: SpinBox {
  /// Creates a two-way binding between a SpinBox control and a GState.
  ///
  /// ```swift
  /// @State var spinValue: Double = 0.0
  ///
  /// SpinBox$()
  ///   .min(0)
  ///   .max(100)
  ///   .value($spinValue) // Two-way binding
  /// ```
  func value(_ state: GState<Double>) -> Self {
    var s = self
    s.ops.append { node in
      node.value = state.wrappedValue
      _ = node.valueChanged.connect { newValue in
        state.wrappedValue = newValue
      }
      state.observe(owner: node) { newValue in
        node.value = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for LineEdit

public extension GNode where T: LineEdit {
  /// Creates a two-way binding between a LineEdit control and a GState.
  ///
  /// ```swift
  /// @State var username: String = ""
  ///
  /// LineEdit$()
  ///   .placeholderText("Enter username")
  ///   .text($username)  // Two-way binding
  /// ```
  func text(_ state: GState<String>) -> Self {
    var s = self
    s.ops.append { node in
      node.text = state.wrappedValue
      _ = node.textChanged.connect { newText in
        state.wrappedValue = newText
      }
      state.observe(owner: node) { newValue in
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for TextEdit

public extension GNode where T: TextEdit {
  /// Creates a two-way binding between a TextEdit control and a GState.
  ///
  /// ```swift
  /// @State var notes: String = ""
  ///
  /// TextEdit$()
  ///   .text($notes)  // Two-way binding
  /// ```
  func text(_ state: GState<String>) -> Self {
    var s = self
    s.ops.append { node in
      node.text = state.wrappedValue
      _ = node.textChanged.connect {
        state.wrappedValue = node.text
      }
      state.observe(owner: node) { newValue in
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for CodeEdit

public extension GNode where T: CodeEdit {
  /// Creates a two-way binding between a CodeEdit control and a GState.
  ///
  /// ```swift
  /// @State var code: String = ""
  ///
  /// CodeEdit$()
  ///   .text($code)  // Two-way binding
  /// ```
  func text(_ state: GState<String>) -> Self {
    var s = self
    s.ops.append { node in
      node.text = state.wrappedValue
      _ = node.textChanged.connect {
        state.wrappedValue = node.text
      }
      state.observe(owner: node) { newValue in
        if node.text != newValue {
          node.text = newValue
        }
      }
    }
    return s
  }
}

// MARK: - Two-way binding for BaseButton

public extension GNode where T: BaseButton {
  /// Creates a two-way binding between a BaseButton control and a GState.
  ///
  /// ```swift
  /// @State var isEnabled: Bool = false
  ///
  /// CheckBox$()
  ///   .text("Enable feature")
  ///   .pressed($isEnabled)  // Two-way binding
  /// ```
  func pressed(_ state: GState<Bool>) -> Self {
    var s = self
    s.ops.append { node in
      node.buttonPressed = state.wrappedValue
      _ = node.toggled.connect { pressed in
        state.wrappedValue = pressed
      }
      state.observe(owner: node) { newValue in
        node.buttonPressed = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for OptionButton

public extension GNode where T: OptionButton {
  /// Creates a two-way binding between an OptionButton control and a GState.
  ///
  /// ```swift
  /// @State var selectedOption: Int = 0
  ///
  /// OptionButton$()
  ///   .selected($selectedOption)  // Two-way binding
  /// ```
  func selected(_ state: GState<Int>) -> Self {
    var s = self
    s.ops.append { node in
      node.select(idx: Int32(state.wrappedValue))
      _ = node.itemSelected.connect { index in
        state.wrappedValue = Int(index)
      }
      state.observe(owner: node) { newValue in
        node.select(idx: Int32(newValue))
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ItemList

public extension GNode where T: ItemList {
  /// Creates a two-way binding between an ItemList control and a GState.
  ///
  /// ```swift
  /// @State var selectedItem: Int = -1
  ///
  /// ItemList$()
  ///   .selected($selectedItem)  // Two-way binding
  /// ```
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
      state.observe(owner: node) { newValue in
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

public extension GNode where T: TabBar {
  /// Creates a two-way binding between a TabBar control and a GState.
  ///
  /// ```swift
  /// @State var currentTab: Int = 0
  ///
  /// TabBar$()
  ///   .currentTab($currentTab)  // Two-way binding
  /// ```
  func currentTab(_ state: GState<Int>) -> Self {
    var s = self
    s.ops.append { node in
      node.currentTab = Int32(state.wrappedValue)
      _ = node.tabSelected.connect { tab in
        state.wrappedValue = Int(tab)
      }
      state.observe(owner: node) { newValue in
        node.currentTab = Int32(newValue)
      }
    }
    return s
  }
}

// MARK: - Two-way binding for TabContainer

public extension GNode where T: TabContainer {
  /// Creates a two-way binding between a TabContainer control and a GState.
  ///
  /// ```swift
  /// @State var currentTab: Int = 0
  ///
  /// TabContainer$()
  ///   .currentTab($currentTab)  // Two-way binding
  /// ```
  func currentTab(_ state: GState<Int>) -> Self {
    var s = self
    s.ops.append { node in
      node.currentTab = Int32(state.wrappedValue)
      _ = node.tabSelected.connect { tab in
        state.wrappedValue = Int(tab)
      }
      state.observe(owner: node) { newValue in
        node.currentTab = Int32(newValue)
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ColorPicker

public extension GNode where T: ColorPicker {
  /// Creates a two-way binding between a ColorPicker control and a GState.
  ///
  /// ```swift
  /// @State var selectedColor: Color = .white
  ///
  /// ColorPicker$()
  ///   .color($selectedColor)  // Two-way binding
  /// ```
  func color(_ state: GState<Color>) -> Self {
    var s = self
    s.ops.append { node in
      node.color = state.wrappedValue
      _ = node.colorChanged.connect { newColor in
        state.wrappedValue = newColor
      }
      state.observe(owner: node) { newValue in
        node.color = newValue
      }
    }
    return s
  }
}

// MARK: - Two-way binding for ColorPickerButton

public extension GNode where T: ColorPickerButton {
  /// Creates a two-way binding between a ColorPickerButton control and a GState.
  ///
  /// ```swift
  /// @State var selectedColor: Color = .white
  ///
  /// ColorPickerButton$()
  ///   .color($selectedColor)  // Two-way binding
  /// ```
  func color(_ state: GState<Color>) -> Self {
    var s = self
    s.ops.append { node in
      node.color = state.wrappedValue
      _ = node.colorChanged.connect { newColor in
        state.wrappedValue = newColor
      }
      state.observe(owner: node) { newValue in
        node.color = newValue
      }
    }
    return s
  }
}
