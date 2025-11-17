export default `import SwiftGodot
import SwiftGodotBuilder

struct InventoryHUD: GView {
  let items: State<[Item]>

  var body: some GView {
    CanvasLayer$ {
      HBoxContainer$ {
        Label$()
          .text("Inventory:")

        ForEach(items) { item in
          Label$()
            .bind(\\.text, to: item, \\.id)
        }
      }
      .offset(top: 10, left: 10)
    }
  }
}`;
