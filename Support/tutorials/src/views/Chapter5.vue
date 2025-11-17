<template>
  <tutorial>
    <div slot="eyebrow">
      SwiftGodotBuilder
    </div>

    <div slot="title">
      Swift Runner – Chapter 5: Combat
    </div>

    <div slot="intro">
      <strong>Goal:</strong> Add combat mechanics including attack actions, health systems, and enemy destruction. Learn
      about state-based combat and collision-based damage.
    </div>

    <!-- SECTION 1: INPUT SETUP -->
    <tutorial-section>
      <div slot="name">Section 1</div>

      <div slot="title">
        Setting Up Attack Input
      </div>

      <div slot="intro">
        First, we need to add an attack action to the input map so the player can attack using the X key.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Add Attack Input</div>

        <p>
          Add the attack action to your <code>setupInput()</code> function in <code>Game.swift</code>.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="inputMapCombatSwift" :highlight-lines="['27:29']" lang="swift"
            title="Sources/SwiftRunner/Game.swift" />
        </aside>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 2: GAMEVIEW ATTACK STATE -->
    <tutorial-section>
      <div slot="name">Section 2</div>

      <div slot="title">
        Setting Up Attack State
      </div>

      <div slot="intro">
        Add attack state tracking to GameView that can be shared across the game.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Add Attack State to GameView</div>

        <p>
          Add an attack state variable to <code>GameView</code> to track whether the player is attacking.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewCombatSwift" :highlight-lines="['6:6']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>

        <div slot="after">
          <p>
            We track the attack state in GameView so it can be shared across multiple systems (player visuals, enemy
            damage, etc.).
          </p>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Update PlayerView Instantiation</div>

        <p>
          Modify the <code>PlayerView</code> call in <code>GameView</code> to pass the attack state binding.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewCombatSwift" :highlight-lines="['23:23']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>

        <div slot="after">
          <p>
            We're now passing <code>$isAttacking</code> (a binding to the state variable) to PlayerView so it can react
            to attack state changes.
          </p>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Check Attack Input</div>

        <p>
          In GameView's <code>onProcess</code> block, check if the attack action is pressed.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewCombatSwift" :highlight-lines="['34:36']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 3: PLAYER ATTACK VISUALS -->
    <tutorial-section>
      <div slot="name">Section 3</div>

      <div slot="title">
        Player Attack Visuals
      </div>

      <div slot="intro">
        Update PlayerView to change color when attacking.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Pass Attack State to PlayerView</div>

        <p>
          Update PlayerView to accept the attack state as a parameter.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="playerViewCombatSwift" :highlight-lines="['11:12']" lang="swift"
            title="Sources/SwiftRunner/PlayerView.swift" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Bind Color to Attack State</div>

        <p>
          Use <code>.bind()</code> to automatically update the color whenever the attack state changes.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="playerViewCombatSwift" :highlight-lines="['20:20']" lang="swift"
            title="Sources/SwiftRunner/PlayerView.swift" />
        </aside>

        <div slot="after">
          <p>
            <strong>Why not <code>.color(isAttacking ? .orange : .darkGray)</code>?</strong>
          </p>
          <br>
          <p>
            That expression would only be evaluated once, when the view is first built.
          </p>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Attack Visual</div>

        <p>
          Build and run the game. Press and hold the X key to see the player turn orange!
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuildAndRun" lang="bash" />
        </aside>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 4: ENEMY COMBAT EVENTS -->
    <tutorial-section>
      <div slot="name">Section 4</div>

      <div slot="title">
        Enemy Combat System
      </div>

      <div slot="intro">
        Create the combat event system and detect when the player attacks enemies.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Add Combat Event</div>

        <p>
          Add an <code>enemyHit</code> case to the existing <code>GameEvent</code> enum.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameEventSwift" :highlight-lines="['6:6']" lang="swift"
            title="Sources/SwiftRunner/GameEvent.swift" />
        </aside>

        <div slot="after">
          <p>
            This event carries a reference to the enemy Area2D node, allowing GameView to identify which enemy was hit.
          </p>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Emit Hit Event on Collision</div>

        <p>
          When the player collides with an enemy while attacking, emit the <code>enemyHit</code> event.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="enemyViewHealthSwift" :highlight-lines="['35:39']" lang="swift"
            title="Sources/SwiftRunner/EnemyView.swift" />
        </aside>

        <div slot="after">
          <p>
            The <code>bodyEntered</code> signal fires when a body enters the enemy's area. If the player is attacking,
            we emit the <code>enemyHit</code> event with a reference to the enemy node.
          </p>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 5: HANDLING ENEMY DESTRUCTION -->
    <tutorial-section>
      <div slot="name">Section 5</div>

      <div slot="title">
        Handling Enemy Destruction
      </div>

      <div slot="intro">
        Subscribe to combat events and destroy enemies when they're hit.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Handle Enemy Hit Events</div>

        <p>
          Subscribe to <code>enemyHit</code> events and destroy enemies immediately when hit.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewEnemiesSwift" :highlight-lines="['42:43']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 6: TESTING -->
    <tutorial-section>
      <div slot="name">Section 6</div>

      <div slot="title">
        Testing Combat
      </div>

      <div slot="intro">
        Build and test the combat system.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Build & Run</div>

        <p>
          Build and run the game.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuildAndRun" lang="bash" />
        </aside>

      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Combat</div>

        <p>
          Try attacking the enemy. Walk into it while pressing X, and it should disappear immediately!
        </p>

        <aside slot="aside">
          <img src="../assets/ss4.png" width="680" height="auto">
        </aside>
      </tutorial-step>
    </tutorial-section>

    <div slot="footer">
      <h1>Outstanding!</h1>
      <h2>You've added combat to your game!</h2>
    </div>
  </tutorial>
</template>

<script>
import playerViewCombatSwift from '@/assets/playerViewCombatSwift';
import enemyViewHealthSwift from '@/assets/enemyViewHealthSwift';
import inputMapCombatSwift from '@/assets/inputMapCombatSwift';
import gameEventSwift from '@/assets/gameEventSwift';
import gameViewCombatSwift from '@/assets/gameViewCombatSwift';
import gameViewEnemiesSwift from '@/assets/gameViewEnemiesSwift';

export default {
  name: 'Chapter5',
  data() {
    return {
      // Code assets
      playerViewCombatSwift,
      enemyViewHealthSwift,
      inputMapCombatSwift,
      gameEventSwift,
      gameViewCombatSwift,
      gameViewEnemiesSwift,

      // Bash commands
      bashBuild: `./build.sh`,
      bashBuildAndRun: `./build.sh
/Applications/Godot.app/Contents/MacOS/Godot --path GodotProject`
    };
  }
};
</script>
