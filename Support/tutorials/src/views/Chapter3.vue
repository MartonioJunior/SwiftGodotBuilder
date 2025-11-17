<template>
  <tutorial>
    <div slot="eyebrow">
      SwiftGodotBuilder
    </div>

    <div slot="title">
      Swift Runner – Chapter 3: Collectibles
    </div>

    <div slot="intro">
      <strong>Goal:</strong> Add collectible items that the player can pick up. Learn about event systems and Area2D
      collision detection.
    </div>

    <!-- SECTION 1: GAME EVENTS -->
    <tutorial-section>
      <div slot="name">Section 1</div>

      <div slot="title">
        Game Events
      </div>

      <div slot="intro">
        First, let's create an event system for game-wide communication. This lets child views notify parent views when
        something happens (like collecting an item).
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create GameEvent Enum</div>

        <p>
          Create a new file <code>GameEvent.swift</code> with an enum for game events.
        </p>
        <hr>
        <p>
          The <code>EmittableEvent</code> protocol allows events to be emitted from anywhere in your game.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameEventSwift" lang="swift" title="Sources/SwiftRunner/GameEvent.swift" />
        </aside>

        <div slot="after">
          <strong>Key Concepts:</strong>
          <ul>
            <li><code>EmittableEvent</code> protocol enables the <code>.emit()</code> method</li>
            <li>Events can carry data (like which item was collected)</li>
          </ul>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 2: UPDATE GAMEVIEW -->
    <tutorial-section>
      <div slot="name">Section 2</div>

      <div slot="title">
        Update GameView
      </div>

      <div slot="intro">
        Now let's update GameView to add a collectible and subscribe to events.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Subscribe to Events</div>

        <p>
          Add an <code>.onEvent</code> handler to listen for item collection events.
        </p>
        <hr>
        <p>
          When an item is collected, this handler will add it to the inventory.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewEventsSwift" :highlight-lines="['27:32']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>

        <div slot="after">
          <p>
            The <code>onEvent</code> modifier subscribes to all <code>GameEvent</code> types and handles them with a
            switch statement.
          </p>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 3: COLLECTIBLES -->
    <tutorial-section>
      <div slot="name">Section 3</div>

      <div slot="title">
        Collectible Items
      </div>

      <div slot="intro">
        Now let's create the CollectibleView that detects when the player picks up an item.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create CollectibleView</div>

        <p>
          Create <code>Sources/SwiftRunner/CollectibleView.swift</code>.
        </p>
        <hr>
        <p>
          This view uses <code>Area2D</code> to detect when the player enters its collision area.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="collectibleViewSwift" lang="swift"
            title="Sources/SwiftRunner/CollectibleView.swift" />
        </aside>

        <div slot="after">
          <strong>How Collectibles Work:</strong>
          <ul>
            <li><code>onSignal(\.bodyEntered)</code> triggers when something enters the area</li>
            <li><code>guard !isCollected else { return }</code> prevents collecting the item multiple times</li>
            <li><code>isCollected = true</code> marks the item as collected before emitting the event</li>
            <li><code>GameEvent.itemCollected(itemType).emit()</code> notifies the parent view</li>
            <li><code>node.queueFree()</code> removes the collectible from the scene</li>
          </ul>
          <p>
            The guard check is important because <code>bodyEntered</code> can fire multiple times in a single frame.
            Setting <code>isCollected = true</code> immediately prevents duplicate collection events.
          </p>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 4: ADD TO GAME -->
    <tutorial-section>
      <div slot="name">Section 4</div>

      <div slot="title">
        Add to Game
      </div>

      <tutorial-step slot="step">
        <div slot="name">Add Collectible to GameView</div>

        <p>
          Add a collectible knife to your game world.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewCollectiblesSwift" :highlight-lines="['24:25']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Build & Run</div>

        <p>
          Build and run the game. Walk over the yellow square to collect the knife!
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Collectibles</div>

        <p>
          You should see the knife added to your inventory when you collect it. The yellow square should disappear
          when
          collected.
        </p>

        <aside slot="aside">
          <img src="../assets/ss3.png" width="680" height="auto">
        </aside>
      </tutorial-step>
    </tutorial-section>

    <div slot="footer">
      <h1>Excellent!</h1>
      <h2>You've created a game with collectible items!</h2>
    </div>
  </tutorial>
</template>

<script>
import gameEventSwift from '@/assets/gameEventSwift';
import gameViewEventsSwift from '@/assets/gameViewEventsSwift';
import collectibleViewSwift from '@/assets/collectibleViewSwift';
import gameViewCollectiblesSwift from '@/assets/gameViewCollectiblesSwift';
import playerViewChapter3Swift from '@/assets/playerViewChapter3Swift';

export default {
  name: 'Chapter3',
  data() {
    return {
      // Code assets
      gameEventSwift,
      gameViewEventsSwift,
      collectibleViewSwift,
      gameViewCollectiblesSwift,
      playerViewChapter3Swift,

      // Bash commands
      bashBuild: `./build.sh`
    };
  }
};
</script>
