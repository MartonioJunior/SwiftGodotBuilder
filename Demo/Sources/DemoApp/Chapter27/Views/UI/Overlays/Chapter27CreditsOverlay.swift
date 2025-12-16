import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct CreditsOverlay: GView {
    let router: ObservableState<GameRouter>

    @State var isVisible = false

    var creditsText: String {
      """
      [center][color=#00FFFF][font_size=24]CHAPTER 26[/font_size][/color]
      [color=#FFD700]Credits & Splash Screen[/color]

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]CREATED WITH[/font_size][/color]

      [color=#00FFFF]SwiftGodotBuilder[/color]
      Declarative Godot Development

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]PROGRAMMING[/font_size][/color]

      [color=#AAAAAA]John Susek[/color]
      Lead Developer

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]POWERED BY[/font_size][/color]

      [color=#478CBF]Godot Engine[/color]
      Open Source Game Engine

      [color=#F05138]SwiftGodot[/color]
      Swift Language Bindings

      [color=#888888]─────────────────[/color]

      [color=#FFFFFF][font_size=16]SPECIAL THANKS[/font_size][/color]

      [color=#AAAAAA]Miguel de Icaza[/color]
      SwiftGodot Creator

      [color=#AAAAAA]SwiftGodot Discord[/color]
      For Feedback and Encouragement

      [color=#888888]─────────────────[/color]

      [color=#FFD700][font_size=16]THANK YOU FOR PLAYING![/font_size][/color]
      """
    }

    var body: some GView {
      Control$ {
        SwiftGodotBuilder.CreditsOverlay(
          isVisible: $isVisible,
          creditsText: creditsText
        ) {
          router.navigate(to: .welcome, transition: .fade())
        }
      }
      .watch(router, \.scene) { _, scene in
        isVisible = scene == .credits
      }
    }
  }
}
