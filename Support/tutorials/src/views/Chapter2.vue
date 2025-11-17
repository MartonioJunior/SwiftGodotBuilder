<template>
  <tutorial>
    <div slot="eyebrow">
      SwiftGodotBuilder
    </div>

    <div slot="title">
      Swift Runner – Chapter 2: Jumping, Camera, and Inventory
    </div>

    <div slot="intro">
      <strong>Goal:</strong> Add jumping mechanics, camera follow, and player inventory. Learn about state management,
      value binding, and dynamic views.
    </div>

    <!-- STEP 1: JUMP MECHANICS -->
    <tutorial-section>
      <div slot="name">Section 1</div>

      <div slot="title">
        Jump Mechanics
      </div>

      <div slot="intro">
        Let's add basic jumping to our player character. We'll only allow jumping when the player is on the ground.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Update PlayerView</div>

        <p>
          Update your <code>PlayerView.swift</code> to add jumping.
        </p>
        <hr>
        <ul>
          <li>Add <code>jumpForce</code> constant (negative Y for upward movement)</li>
          <li>Check if "jump" action is pressed</li>
          <li>Only jump if <code>player.isOnFloor()</code> returns true</li>
        </ul>

        <aside slot="aside">
          <tutorial-highlighter :text="playerViewJumpSwift" :highlight-lines="['9:9', '47:50']" lang="swift"
            title="Sources/SwiftRunner/PlayerView.swift" />
        </aside>

        <div slot="after">
          <strong>How it works:</strong>
          <ul>
            <li><code>isOnFloor()</code> detects if the character is touching a floor collision</li>
            <li><code>isActionJustPressed</code> triggers only once per key press (not held)</li>
            <li>Negative Y velocity moves the character upward</li>
          </ul>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Register Jump Action</div>

        <p>
          Add the jump action to your <code>setupInput()</code> function in <code>Game.swift</code>.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameSwiftJump" :highlight-lines="['23:25']" lang="swift"
            title="Sources/SwiftRunner/Game.swift" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test It Out</div>

        <p>
          Build and run the game. Press Space to jump!
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>

        <div slot="after">
          <p>
            Great! Now you have a character that can jump. Let's continue adding features!
          </p>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- STEP 2: CAMERA FOLLOW -->
    <tutorial-section>
      <div slot="name">Section 2</div>

      <div slot="title">
        Camera Follow
      </div>

      <div slot="intro">
        Add a camera that follows the player around the world.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Add Camera2D</div>

        <p>
          Add a <code>Camera2D</code> as a child of the player.
        </p>
        <hr>
        <p>
          When a Camera2D is a child of a moving node, it automatically follows that node.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewCameraSwift" :highlight-lines="['23:25']" lang="swift"
            title="Sources/SwiftRunner/PlayerView.swift" />
        </aside>

        <div slot="after">
          <strong>Camera2D Features:</strong>
          <ul>
            <li>Automatically centers the viewport on its position</li>
            <li>When parented to a node, it follows that node's movement</li>
            <li>Set <code>.enabled(true)</code> to make it the active camera</li>
            <li>You can add smoothing with <code>.smoothingEnabled(true)</code></li>
          </ul>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Camera</div>

        <p>
          Build and run. The camera now follows the player!
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>
      </tutorial-step>
    </tutorial-section>

    <!-- STEP 3: ITEMS & INVENTORY -->
    <tutorial-section>
      <div slot="name">Section 3</div>

      <div slot="title">
        Items & Inventory
      </div>

      <div slot="intro">
        Create collectible items and track them in a player inventory using state management.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Define Item Enum</div>

        <p>
          First, let's define an <code>Item</code> enum to represent the types of items our player can collect.
        </p>
        <hr>
        <p>
          Create a new file called <code>Item.swift</code> with an enum defining our item types:
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="itemEnumSwift" lang="swift" title="Sources/SwiftRunner/Item.swift" />
        </aside>

        <div slot="after">
          <ul>
            <li><code>Identifiable</code> protocol is needed for using items with <code>ForEach</code></li>
            <li>The <code>id</code> property uses <code>rawValue</code> to uniquely identify each item type</li>
          </ul>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Add @State for Inventory</div>

        <p>
          Now let's add an inventory to <code>GameView</code> using the <code>@State</code> property wrapper.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewWithInventorySwift" :highlight-lines="['5:5', '24:25']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Add InventoryHUD</div>

        <p>
          Add the <code>InventoryHUD</code> to your GameView to display the inventory on screen.
        </p>
        <hr>
        <p>
          Pass the inventory state using <code>$inventory</code> syntax.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewWithInventorySwift" :highlight-lines="['24:24']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>

        <div slot="after">
          The <code>$</code> prefix creates a binding that allows child views to observe changes
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Create Inventory HUD</div>

        <p>
          Create a HUD that displays the current inventory to the player.
        </p>
        <hr>
        <p>
          The HUD uses <code>ForEach</code> to dynamically create a label for each item in the inventory.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="inventoryHUDSwift" :highlight-lines="['15:15']" lang="swift"
            title="Sources/SwiftRunner/InventoryHUD.swift" />
        </aside>

        <div slot="after">
          <ul>
            <li><code>bind(\.text, to: item, \.id)</code> binds the label text to the item's id property</li>
            <li>The id property returns the raw value ("Knife" or "Boots") for display</li>
            <li>When items are added/removed, the UI automatically updates</li>
          </ul>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Your Inventory</div>

        <p>
          Build and run the game.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>
      </tutorial-step>


      <tutorial-step slot="step">
        <div slot="name">Results</div>

        <p>You should see:</p>
        <ul>
          <li>"Inventory: Boots" displayed in the top-left corner</li>
          <li>The player centered on the screen</li>
        </ul>

        <aside slot="aside">
          <img src="../assets/ss2.png" width="680" height="auto">
        </aside>

      </tutorial-step>
    </tutorial-section>

    <div slot="footer">
      <h1>Excellent Work!</h1>
      <h2>You've built a platformer with a camera, a jumping player, and inventory!</h2>
      <p>
        In this chapter you learned:
      </p>
      <ul>
        <li><strong>Jump mechanics</strong> with ground detection</li>
        <li><strong>Camera2D</strong> for following the player</li>
        <li><strong>Enums</strong> to define item types</li>
        <li><strong>@State</strong> for reactive inventory management</li>
        <li><strong>ForEach</strong> to dynamically display lists</li>
      </ul>
    </div>
  </tutorial>
</template>

<script>
import playerViewJumpSwift from '@/assets/playerViewJumpSwift';
import gameViewCameraSwift from '@/assets/gameViewCameraSwift';
import itemSwift from '@/assets/itemSwift';
import gameViewItemsSwift from '@/assets/gameViewItemsSwift';
import playerViewInventorySwift from '@/assets/playerViewInventorySwift';
import entryPointChapter2Swift from '@/assets/entryPointChapter2Swift';
import itemEnumSwift from '@/assets/itemEnumSwift';
import gameViewWithInventorySwift from '@/assets/gameViewWithInventorySwift';
import inventoryHUDSwift from '@/assets/inventoryHUDSwift';

export default {
  name: 'Chapter2',
  data() {
    return {
      // Code assets
      playerViewJumpSwift,
      gameViewCameraSwift,
      itemSwift,
      gameViewItemsSwift,
      playerViewInventorySwift,
      entryPointChapter2Swift,
      itemEnumSwift,
      gameViewWithInventorySwift,
      inventoryHUDSwift,

      // Game.swift with jump action
      gameSwiftJump: `import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Game: Node2D {
  override func _ready() {
    setupInput()
    addChild(node: GameView().toNode())
  }

  func setupInput() {
    Actions {
      Action("move_left") {
        Key(.a)
        Key(.left)
      }

      Action("move_right") {
        Key(.d)
        Key(.right)
      }

      Action("jump") {
        Key(.space)
      }
    }
    .install()
  }
}`,

      // Bash commands
      bashBuild: `./build.sh`
    };
  }
};
</script>
