<template>
  <tutorial>
    <div slot="eyebrow">
      SwiftGodotBuilder
    </div>

    <div slot="title">
      Swift Runner – Chapter 4: Enemies
    </div>

    <div slot="intro">
      <strong>Goal:</strong> Add patrolling enemies with simple AI to create challenge and gameplay variety. Learn about
      state-based behavior and movement patterns.
    </div>

    <!-- SECTION 1: CREATE ENEMY COMPONENT -->
    <tutorial-section>
      <div slot="name">Section 1</div>

      <div slot="title">
        Creating the Enemy Component
      </div>

      <div slot="intro">
        Build a reusable enemy component with patrol behavior and state management.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create EnemyView</div>

        <p>
          Create <code>Sources/SwiftRunner/EnemyView.swift</code> with a simple patrol behavior.
        </p>
        <hr>
        <p>
          The enemy will move back and forth within a patrol distance from its starting position.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="enemyViewSwift" :highlight-lines="['9:10', '28:28', '32:34']" lang="swift"
            title="Sources/SwiftRunner/EnemyView.swift" />
        </aside>

        <div slot="after">
          <strong>Understanding Enemy Patrol:</strong>
          <ul>
            <li><code>@State var position</code> tracks the enemy's current position</li>
            <li><code>@State var movingRight</code> tracks the current patrol direction</li>
            <li><code>onProcess</code> updates the position every frame</li>
            <li>The position binding (<code>$position</code>) automatically updates the node</li>
          </ul>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">How the Patrol Logic Works</div>

        <p>
          Let's break down the <code>updatePatrol</code> function.
        </p>
        <hr>
        <p>
          The function calculates min/max boundaries, moves the enemy, and reverses direction at boundaries.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="enemyViewSwift" :highlight-lines="['37:53']" lang="swift"
            title="Sources/SwiftRunner/EnemyView.swift" />
        </aside>

        <div slot="after">
          <strong>Key Points:</strong>
          <ul>
            <li><code>minX</code> and <code>maxX</code> define the patrol area</li>
            <li>Position updates every frame based on <code>speed * delta</code></li>
            <li>When position reaches a boundary, <code>movingRight</code> flips</li>
          </ul>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- SECTION 2: INTEGRATION AND TESTING -->
    <tutorial-section>
      <div slot="name">Section 2</div>

      <div slot="title">
        Adding Enemies to Your Game
      </div>

      <div slot="intro">
        Integrate the enemy into your game world and test the patrol behavior.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Add Enemy to GameView</div>

        <p>
          Add an enemy to your game world.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewEnemiesSwift" :highlight-lines="['28:28']" lang="swift"
            title="Sources/SwiftRunner/GameView.swift" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Your Enemy</div>

        <p>
          Build and run the game. Watch the red square patrol back and forth!
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>

        <div slot="after">
          <p>
            The enemy should smoothly patrol within its defined range. Try adjusting the <code>patrolDistance</code> and
            <code>speed</code> values to see how it affects the behavior.
          </p>
        </div>
      </tutorial-step>
    </tutorial-section>

    <div slot="footer">
      <h1>Fantastic!</h1>
      <h2>You've created a game with patrolling enemies!</h2>
    </div>
  </tutorial>
</template>

<script>
import enemyViewSwift from '@/assets/enemyViewSwift';
import gameViewEnemiesSwift from '@/assets/gameViewEnemiesSwift';

export default {
  name: 'Chapter4',
  data() {
    return {
      // Code assets
      enemyViewSwift,
      gameViewEnemiesSwift,

      // Bash commands
      bashBuild: `./build.sh`
    };
  }
};
</script>
