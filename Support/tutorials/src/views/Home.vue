<template>
  <main class="vue-tut">
    <header class="tutorial-header">
      <h2 class="m-s-xl">SwiftGodotBuilder Tutorials</h2>
    </header>
    <div class="sections">
      <div class="tutorial-section">

        <div class="step-container">
          <div class="step p-w-med p-e-xl p-n-lg p-s-lg">
            <h1 class="m-s-xs">Swift Runner</h1>

            <main>
              <h5 class="m-s-xl">Learn SwiftGodotBuilder by building a complete 2D platformer game</h5>

              <h3 class="m-n-med m-s-xs">
                <router-link to="/swift-runner/chapter-1">Chapter 1: Basic Movement</router-link>
              </h3>

              <p>This interactive tutorial will guide you step-by-step through creating a platformer character with
                movement,
                gravity, and collision detection.</p>

              <h3 class="m-n-med m-s-xs">
                <router-link to="/swift-runner/chapter-2">Chapter 2: Jumping, Camera, and Inventory</router-link>
              </h3>

              <p>Add jumping mechanics, camera follow, and player inventory. Learn about state management, value
                binding, and
                dynamic views.</p>

              <h3 class="m-n-med m-s-xs">
                <router-link to="/swift-runner/chapter-3">Chapter 3: Collectibles</router-link>
              </h3>

              <p>Add collectible items that the player can pick up. Learn about event systems and Area2D collision
                detection.</p>

              <h3 class="m-n-med m-s-xs">
                <router-link to="/swift-runner/chapter-4">Chapter 4: Enemies</router-link>
              </h3>

              <p>Add patrolling enemies with simple AI to create challenge and gameplay variety. Learn about state-based
                behavior and movement patterns.</p>

              <h3 class="m-n-med m-s-xs">
                <router-link to="/swift-runner/chapter-5">Chapter 5: Combat</router-link>
              </h3>

              <p>Add combat mechanics including attack actions, health systems, and enemy destruction. Learn about
                state-based combat and collision-based damage.</p>

            </main>

          </div>
        </div>
      </div>

      <div class="tutorial-section">
        <div class="step-container">
          <div class="step p-w-med p-e-xl p-n-lg p-s-lg">
            <h2 class="m-s-xs">Suggested Reading</h2>

            <main>
              <div class="d-flex m-n-xl flex-gap-lg align-items-start">
                <a href="https://mitpress.mit.edu/9780262542692/characteristics-of-games/" target="_blank">
                  <img src="../assets/cog.jpg" width="150" alt="Characteristics of Games">
                </a>
                <div style="max-width: 500px;">
                  <h4 class="m-s-xs">
                    <a href="https://mitpress.mit.edu/9780262542692/characteristics-of-games/"
                      target="_blank"><strong>Characteristics of Games</strong></a>
                  </h4>
                  <p>
                    If you are serious about making fun games people actually want to play, it is strongly recommended
                    you read this book.
                  </p>
                </div>
              </div>
            </main>

          </div>
        </div>
      </div>
    </div>
  </main>
</template>

<style>
h5 {
  color: #6d6d6d;
  font-weight: normal;
  font-size: initial;
}

a {
  color: #0066cc;
  text-decoration: none;
}

a:visited {
  color: #0066cc;
}

a:hover {
  color: #0052a3;
  text-decoration: underline;
}

a:active {
  color: #004080;
}

.flex-gap-lg {
  gap: 20px;
}

.align-items-start {
  align-items: flex-start;
}

h4 {
  font-weight: initial;
  font-size: 18px;
}
</style>
