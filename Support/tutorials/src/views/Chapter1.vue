<template>
  <tutorial>
    <div slot="eyebrow">
      SwiftGodotBuilder
    </div>

    <div slot="title">
      Swift Runner – Chapter 1: Basic Movement
    </div>

    <div slot="intro">
      <strong>Goal:</strong> Create a player character that can move left and right, fall with gravity, and collide with
      the ground.
    </div>

    <!-- STEP 1: PROJECT SETUP -->
    <tutorial-section>
      <div slot="name">Section 1</div>

      <div slot="title">
        Project Setup
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create Swift Package</div>

        <p>
          First, let's create a new Swift Package for our game.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashStep1" lang="bash" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Configure Package.swift</div>

        <p>
          Update your <code>Package.swift</code>:
        <ul>
          <li>Specify macOS platform version to match SwiftGodot</li>
          <li>Set library type to dynamic for GDExtension</li>
          <li>Add SwiftGodotBuilder as a dependency</li>
        </ul>
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="packageSwift" :highlight-lines="['6:6', '10:10', '14:16', '20:20']" lang="swift"
            title="Package.swift" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Create Project Directory</div>

        <p>
          Create the Godot project directory structure.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashMkdir" lang="bash" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Create Main Scene</div>

        <p>
          Create <code>GodotProject/root.tscn</code> - this is the main scene file.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="rootTscn" lang="ini" title="GodotProject/root.tscn" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Configure Godot Project</div>

        <p>
          Create <code>GodotProject/project.godot</code> - this is the Godot project configuration.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="projectGodot" lang="ini" title="GodotProject/project.godot" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Create GDExtension File</div>

        <p>
          Create <code>GodotProject/SwiftRunner.gdextension</code> - this tells Godot where to find your compiled Swift
          library.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gdextension" lang="ini" title="GodotProject/SwiftRunner.gdextension" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Create Build Script</div>

        <p>
          Create a <code>build.sh</code> script to make building easier.
        </p>
        <hr>
        <p>
          Make it executable with <code>chmod +x build.sh</code>
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="buildScript" lang="bash" title="build.sh" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Test Build</div>

        <p>
          Test the build process. If the build succeeds, you're ready to continue!
        </p>
        <hr>
        <p>Having trouble? Join the <a href="https://discord.com/channels/1395045530341736548/1395045610515857578"
            target="_blank">SwiftGodot Discord</a>.</p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>

        <div slot="after">
          <strong>What You've Learned:</strong>
          <ul>
            <li>SwiftGodot games are built as dynamic libraries</li>
            <li>A <code>.gdextension</code> file tells Godot where to find your compiled Swift library</li>
            <li>Godot projects and scenes are ini-like text files</li>
            <li>Your built library needs to be copied into the Godot project directory</li>
          </ul>
        </div>

      </tutorial-step>
    </tutorial-section>

    <!-- STEP 2: CREATE GAME SCENE -->
    <tutorial-section>
      <div slot="name">Section 2</div>

      <div slot="title">
        Create the Game Scene
      </div>

      <div slot="intro">
        The Game class is our main entry point, registered with Godot using the <code>@Godot</code> macro.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create Game Class</div>

        <p>
          Create <code>Sources/SwiftRunner/Game.swift</code> with the Game class.
        </p>
        <hr>
        <p>
          This class sets up input actions and adds the GameView to the scene.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameSwift" lang="swift" title="Sources/SwiftRunner/Game.swift" />
        </aside>

        <div slot="after">
          <strong>Key Concepts:</strong>
          <ul>
            <li><code>@Godot</code> macro makes the class available to Godot</li>
            <li><code>_ready()</code> is called when the node enters the scene</li>
            <li><code>setupInput()</code> registers keyboard controls</li>
          </ul>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- STEP 3: BUILD GAME VIEW -->
    <tutorial-section>
      <div slot="name">Section 3</div>

      <div slot="title">
        Build the Game View
      </div>

      <div slot="intro">
        The GameView contains our game world: the ground platform and player character.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create GameView</div>

        <p>
          Create <code>Sources/SwiftRunner/GameView.swift</code> with a ground platform and player.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="gameViewSwift" lang="swift" title="Sources/SwiftRunner/GameView.swift" />
        </aside>

        <div slot="after">
          <strong>Breaking it down:</strong>
          <ul>
            <li><code>StaticBody2D$</code> is a physics body that doesn't move (the ground)</li>
            <li><code>ColorBox$</code> renders a colored rectangle in world space</li>
            <li><code>CollisionShape2D$</code> defines the physical collision shape</li>
            <li><code>PlayerView</code> is our player character (created next)</li>
          </ul>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- STEP 4: CREATE PLAYER CHARACTER -->
    <tutorial-section>
      <div slot="name">Section 4</div>

      <div slot="title">
        Create the Player Character
      </div>

      <div slot="intro">
        The player uses <code>CharacterBody2D$</code> for physics-based movement with collision detection.
      </div>

      <tutorial-step slot="step">
        <div slot="name">Create PlayerView</div>

        <p>
          Create <code>Sources/SwiftRunner/PlayerView.swift</code>.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="playerViewSwift" :highlight-lines="['23:23', '48:48']" lang="swift"
            title="Sources/SwiftRunner/PlayerView.swift" />
        </aside>

        <div slot="after">
          <strong>Understanding the code:</strong>
          <ul>
            <li><code>.onProcess { player, delta in ... }</code> runs every frame</li>
            <li><code>player</code> is the CharacterBody2D node reference</li>
            <li><code>delta</code> is time since last frame (for frame-rate independence)</li>
            <li><code>moveAndSlide()</code> handles movement and collisions automatically</li>
          </ul>
        </div>
      </tutorial-step>
    </tutorial-section>

    <!-- STEP 5: BUILD AND RUN -->
    <tutorial-section>
      <div slot="name">Section 5</div>

      <div slot="title">
        Build and Run
      </div>

      <tutorial-step slot="step">
        <div slot="name">Register Classes</div>

        <p>
          Create the Swift entry point that registers your classes with Godot.
        </p>
        <hr>
        <p>
          Edit <code>Sources/SwiftRunner/SwiftRunner.swift</code>:
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="entryPointSwift" lang="swift" title="Sources/SwiftRunner/SwiftRunner.swift" />
        </aside>

        <div slot="after">
          <p>This registers your <code>Game</code> class plus all SwiftGodotBuilder's built-in classes (like
            <code>ColorBox</code>).</p>
        </div>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Build Swift Library</div>

        <p>
          Build your Swift library and copy it to the Godot project.
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashBuild" lang="bash" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Import Assets</div>

        <p>
          Import project assets into Godot.
        </p>

        <div slot="after">
          <p>
            The first time you add or change files in <code>GodotProject/</code>, they must be imported as project
            assets.
          </p>
        </div>

        <aside slot="aside">
          <tutorial-highlighter :text="bashImport" lang="bash" />
        </aside>
      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Run the Game</div>

        <p>
          Run the game!
        </p>

        <aside slot="aside">
          <tutorial-highlighter :text="bashRun" lang="bash" />
        </aside>

      </tutorial-step>

      <tutorial-step slot="step">
        <div slot="name">Results</div>

        <p>You should see:</p>
        <ul>
          <li>A dark gray square (player) at the top</li>
          <li>A gray rectangle (ground) at the bottom</li>
          <li>The player falls and lands on the ground</li>
          <li>Press A/D or Arrow keys to move left and right</li>
        </ul>

        <aside slot="aside">
          <img src="../assets/ss1.png" width="680" height="auto">
        </aside>

      </tutorial-step>
    </tutorial-section>

    <div slot="footer">
      <h1>Congratulations!</h1>
      <h2>You've built a basic platformer character!</h2>
      <p>
        You now have a player that can move left and right with gravity and collision detection.
      </p>
    </div>
  </tutorial>
</template>

<script>
import packageSwift from '@/assets/packageSwift';
import { rootTscn, projectGodot, gdextension } from '@/assets/godotFiles';
import buildScript from '@/assets/buildScript';
import gameSwift from '@/assets/gameSwift';
import gameViewSwift from '@/assets/gameViewSwift';
import playerViewSwift from '@/assets/playerViewSwift';
import entryPointSwift from '@/assets/entryPointSwift';

export default {
  name: 'Chapter1',
  data() {
    return {
      // Code assets
      packageSwift,
      rootTscn,
      projectGodot,
      gdextension,
      buildScript,
      gameSwift,
      gameViewSwift,
      playerViewSwift,
      entryPointSwift,

      // Bash commands
      bashStep1: `mkdir SwiftRunner
cd SwiftRunner
swift package init --type library`,

      bashMkdir: `mkdir -p GodotProject/bin`,

      bashBuild: `./build.sh`,

      bashImport: `/Applications/Godot.app/Contents/MacOS/Godot --path GodotProject --headless --import`,

      bashRun: `/Applications/Godot.app/Contents/MacOS/Godot --path GodotProject`
    };
  }
};
</script>
