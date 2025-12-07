import SwiftGodotBuilder

extension Chapter25.GameView {
  static func installActions() {
    Actions {
      ActionRecipes.axisLR(
        namePrefix: "move",
        device: 0,
        axis: .leftX,
        dz: 0.2,
        keyLeft: .a,
        keyRight: .d
      )

      ActionRecipes.axisUD(
        namePrefix: "move",
        device: 0,
        axis: .leftY,
        dz: 0.2,
        keyDown: .s,
        keyUp: .w
      )

      Action("move_left") {
        Key(.left)
        JoyButton(.dpadLeft, device: 0)
      }

      Action("move_right") {
        Key(.right)
        JoyButton(.dpadRight, device: 0)
      }

      Action("move_up") {
        Key(.up)
        JoyButton(.dpadUp, device: 0)
      }

      Action("move_down") {
        Key(.down)
        JoyButton(.dpadDown, device: 0)
      }

      Action("jump") {
        Key(.space)
        Key(.w)
        Key(.up)
        JoyButton(.a, device: 0)
        JoyButton(.dpadUp, device: 0)
      }

      Action("attack") {
        Key(.x)
        JoyButton(.x, device: 0)
      }

      Action("dash") {
        Key(.shift)
        JoyButton(.rightShoulder, device: 0)
        JoyButton(.leftShoulder, device: 0)
      }

      Action("switch_weapon") {
        Key(.q)
        JoyButton(.y, device: 0)
      }

      Action("start") {
        Key(.space)
        JoyButton(.a, device: 0)
        JoyButton(.start, device: 0)
      }

      Action("pause") {
        Key(.escape)
        JoyButton(.start, device: 0)
      }

      // UI navigation actions
      Action("ui_up") {
        Key(.up)
        Key(.w)
        JoyButton(.dpadUp, device: 0)
      }

      Action("ui_down") {
        Key(.down)
        Key(.s)
        JoyButton(.dpadDown, device: 0)
      }

      Action("ui_left") {
        Key(.left)
        Key(.a)
        JoyButton(.dpadLeft, device: 0)
      }

      Action("ui_right") {
        Key(.right)
        Key(.d)
        JoyButton(.dpadRight, device: 0)
      }

      Action("ui_accept") {
        Key(.enter)
        Key(.space)
        JoyButton(.a, device: 0)
      }

      Action("ui_cancel") {
        Key(.escape)
        JoyButton(.b, device: 0)
      }

      Action("interact") {
        Key(.e)
        Key(.enter)
        JoyButton(.a, device: 0)
      }
    }.install()
  }
}
