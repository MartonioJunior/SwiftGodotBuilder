# FAQ

## Will this hurt game performance?

No. SwiftGodotBuilder is a build-time library that generates native Godot nodes. Views are converted to standard Godot node operations during initialization. Once your game is running, there's no additional overhead compared to manually creating nodes in code.

## Do I need to use the builder syntax for everything?

No. You can mix and match SwiftGodotBuilder with traditional SwiftGodot code. Use the builder where it helps you and regular SwiftGodot code where that makes more sense. You can convert any `GView` to a `Node` using `.toNode()`.

## Can I use this with existing Godot scenes?

Yes. Use `.fromScene("path.tscn")` to instance existing `.tscn` files within your builder code. You can also add SwiftGodotBuilder nodes as children to traditionally-created nodes.

## Can I use this for non-game applications?

Absolutely! The examples focus on games, but SwiftGodotBuilder works great for any Godot application.

## What platforms are supported?

SwiftGodotBuilder supports the same platforms as SwiftGodot: macOS, iOS, Windows, and Linux.

## Is this production-ready?

SwiftGodotBuilder is under active development. While the core APIs are stable, you should expect occasional breaking changes around the edges. Always check the release notes when updating.
