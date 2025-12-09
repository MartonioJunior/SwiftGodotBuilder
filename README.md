
<a href="#"><img src="media/patterns.png?raw=true" width="210" align="right" title="Pictured: Ancient Roman seamstress at a loom, holding a shuttle."></a>

#### SwiftGodotBuilder

Declarative Godot development.


A SwiftUI-style library for building Godot games and apps using [SwiftGodot](https://github.com/migueldeicaza/SwiftGodot). Integrates with [LDtk](https://ldtk.io) and [Aseprite](https://aseprite.org).

<br>

📕 [API Documentation](https://swiftpackageindex.com/johnsusek/SwiftGodotBuilder/documentation/swiftgodotbuilder)

<br><br>

## Quick Start

Add SwiftGodotBuilder to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/johnsusek/SwiftGodotBuilder", branch: "main")
],
targets: [
  .target(name: "YourTarget", dependencies: ["SwiftGodotBuilder"])
]
```

Then import and use:

```swift
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Game: Node2D {
  override func _ready() {
    addChild(node: GameView().toNode())
  }
}

struct GameView: GView {
  var body: some GView {
    Node2D$ {
      Label$().text("Hello World")
    }
  }
}
```

## Core Features

### Builder Syntax

```swift
// $ syntax - shorthand for GNode<T>
Sprite2D$()
CharacterBody2D$()
Label$()

// With children
Node2D$ {
  Sprite2D$()
  CollisionShape2D$()
}

// Named nodes
CharacterBody2D$("Player") {
  Sprite2D$()
}

// Custom initializer
GNode<CustomNode>("Name", make: { CustomNode(config: config) }) {
  // children
}
```

### Properties & Configuration

```swift
// Dynamic member lookup - set any property
Sprite2D$()
  .position(Vector2(100, 200))
  .scale(Vector2(2, 2))
  .rotation(45)
  .modulate(.red)
  .zIndex(10)

// Configure closure for complex setup
Sprite2D$().configure { sprite in
  sprite.texture = myTexture
  sprite.centered = true
}
```

### Resource Loading

```swift
// Load into property
Sprite2D$()
  .res(\.texture, "player.png")
  .res(\.material, "shader_material.tres")

// Custom resource loading
Sprite2D$()
  .withResource("shader.gdshader", as: Shader.self) { node, shader in
    let material = ShaderMaterial()
    material.shader = shader
    node.material = material
  }
```

### Signal Connections

```swift
// No arguments
Button$()
  .onSignal(\.pressed) { node in
    print("Pressed!")
  }

// With arguments
Area2D$()
  .onSignal(\.bodyEntered) { node, body in
    print("Body entered: \(body)")
  }

// Multiple arguments
Area2D$()
  .onSignal(\.bodyShapeEntered) { node, bodyRid, body, bodyShapeIndex, localShapeIndex in
    // Handle collision
  }
```

### Process Hooks

```swift
Node2D$()
  .onReady { node in
    print("Node ready!")
  }
  .onProcess { node, delta in
    node.position.x += 100 * Float(delta)
  }
  .onPhysicsProcess { node, delta in
    // Physics updates
  }
```

### Custom Components

Create reusable components with slots.

```swift
// Component with a content slot
struct LabeledCell<Content: GView>: GView {
  let label: String
  let content: Content

  init(_ label: String, @GViewBuilder content: () -> Content) {
    self.label = label
    self.content = content()
  }

  var body: some GView {
    VBoxContainer$ {
      Control$ { content }.minSize([64, 64])
      Label$().text(label).horizontalAlignment(.center)
    }
  }
}

// Single child
LabeledCell("Health") {
  ProgressBar$().value(80)
}

// Multiple children (automatically grouped)
LabeledCell("Stats") {
  Label$().text("HP: 100")
  Label$().text("MP: 50")
}
```

## Reactive Data

### State Management

```swift
struct PlayerView: GView {
  @State var health: Int = 100
  @State var position: Vector2 = .zero
  @State var playerNode: CharacterBody2D?

  var body: some GView {
    CharacterBody2D$ {
      Sprite2D$()
      ProgressBar$()
        .value($health)  // One-way binding
    }
    .position($position)  // Bind to property
    .ref($playerNode)     // Capture node reference
    .onProcess { node, delta in
      health -= 1  // Modify state
    }
  }
}
```

#### State Binding Patterns

```swift
// One-way bind to property
ProgressBar$().value($health)

// Bind with formatter
Label$().bind(\.text, to: $score) { "Score: \($0)" }

// Bind to sub-property
Sprite2D$().bind(\.x, to: $position, \.x)

// Multi-state binding
Label$().bind(\.text, to: $health, $maxHealth) { "\($0)/\($1)" }

// Two-way bindings (form controls)
LineEdit$().text($username)
Slider$().value($volume)
CheckBox$().pressed($isEnabled)
OptionButton$().selected($selectedIndex)
```

### Dynamic Views

#### ForEach

```swift
// ForEach - dynamic lists
struct InventoryView: GView {
  @State var items: [Item] = []

  var body: some GView {
    VBoxContainer$ {
      ForEach($items) { item in
        HBoxContainer$ {
          Label$().text(item.wrappedValue.name)
          Button$().text("X").onSignal(\.pressed) { _ in
            items.removeAll { $0.id == item.wrappedValue.id }
          }
        }
      }
    }
  }
}
```

#### If/Else

```swift
// If - conditional rendering
struct MenuView: GView {
  @State var showSettings = false

  var body: some GView {
    VBoxContainer$ {
      If($showSettings) {
        SettingsPanel()
      }
      .Else {
        MainMenu()
      }
    }
  }
}

// If modes
If($condition) { /* ... */ }                 // .hide (default) - toggle visible
If($condition) { /* ... */ }.mode(.remove)   // addChild/removeChild
If($condition) { /* ... */ }.mode(.destroy)  // queueFree/rebuild
```

#### Switch/Case

```swift
// Switch/Case - multi-way branching
enum Page { case mainMenu, levelSelect, settings }

struct GameView: GView {
  @State var currentPage: Page = .mainMenu

  var body: some GView {
    VBoxContainer$ {
      Switch($currentPage) {
        Case(.mainMenu) {
          Label$().text("Main Menu")
          Button$().text("Start").onSignal(\.pressed) { _ in
            currentPage = .levelSelect
          }
        }
        Case(.levelSelect) {
          Label$().text("Level Select")
          Button$().text("Back").onSignal(\.pressed) { _ in
            currentPage = .mainMenu
          }
        }
        Case(.settings) {
          Label$().text("Settings")
        }
      }
      .default {
        Label$().text("Unknown page")
      }
    }
  }
}
```


### Computed Properties

```swift
// Define computed properties as computed vars on the struct
@State var score = 0

var scoreText: GState<String> {
  $score.computed { "Score: \($0)" }
}

var isHighScore: GState<Bool> {
  $score.computed { $0 > 1000 }
}

Label$().text(scoreText)

If(isHighScore) {
  Label$().text("New High Score!").modulate(.yellow)
}

// Combine multiple states
@State var health = 80
@State var maxHealth = 100
@State var playerName = "Hero"

var statusText: GState<String> {
  $health.computed(with: $maxHealth, $playerName) { hp, maxHp, name in
    "\(name): \(hp)/\(maxHp) HP"
  }
}

Label$().text(statusText)
```

### Watchers

```swift
// Watch and react to state changes
Node2D$().watch($health) { node, health in
  node.modulate = health < 20 ? .red : .white
}
```

### Store

```swift
struct GameState {
  var health: Int = 100
  var score: Int = 0
}

enum GameEvent {
  case takeDamage(Int)
  case addScore(Int)
}

func gameReducer(state: inout GameState, event: GameEvent) {
  switch event {
  case .takeDamage(let amount):
    state.health = max(0, state.health - amount)
  case .addScore(let points):
    state.score += points
  }
}

let store = Store(initialState: GameState(), reducer: gameReducer)

// Use in views
ProgressBar$().value(store.state(\.health))
Label$().text(store.state(\.score)) { "Score: \($0)" }

// Send events
store.commit(.takeDamage(10))
store.commit(.addScore(100))

// With middleware for logging/side effects
let store = Store(
  initialState: GameState(),
  reducer: gameReducer,
  middleware: [.logging(name: "Game")]
)

// Custom middleware
let analytics = Middleware<GameState, GameEvent> { event, state, dispatch in
  Analytics.track(event)
}
```

### Persistable

Auto-save `@Observable` classes to disk.

```swift
@Observable
class GameSettings: Persistable {
  static let PersistenceKey = "settings"

  var masterVolume = 0.7
  var musicVolume = 0.6
  var fullscreen = false

  init() { loadPersistence() }

  func toDictionary() -> VariantDictionary {
    let dict = VariantDictionary()
    dict["masterVolume"] = Variant(masterVolume)
    dict["musicVolume"] = Variant(musicVolume)
    dict["fullscreen"] = Variant(fullscreen)
    return dict
  }

  func fromDictionary(_ dict: VariantDictionary) {
    if let v: Double = dict["masterVolume"]?.to() { masterVolume = v }
    if let v: Double = dict["musicVolume"]?.to() { musicVolume = v }
    if let v: Bool = dict["fullscreen"]?.to() { fullscreen = v }
  }
}

// Auto-save on any property change
Node2D$().watchAny($settings) { _, _ in
  settings.savePersistence()
}

// Manual operations
settings.savePersistence()
settings.deletePersistence()
settings.resetPersistence()
```

### EventBus

Modify parent state from children by emitting events instead of using callbacks.

```swift
enum GameEvent {
  case playerDied
  case scoreChanged(Int)
  case itemCollected(String)
}

// Subscribe via modifier
Node2D$()
  .onEvent(GameEvent.self) { node, event in
    switch event {
    case .playerDied: print("Game Over")
    case .scoreChanged(let score): print("Score: \(score)")
    case .itemCollected(let item): print("Got: \(item)")
    }
  }

// Subscribe with filter
Node2D$()
  .onEvent(GameEvent.self, match: { event in
    if case .scoreChanged = event { return true }
    return false
  }) { node, event in
    // Handle only score changes
  }

// Publish via ServiceLocator
let bus = ServiceLocator.resolve(GameEvent.self)
bus.publish(.scoreChanged(100))

// Or use EmittableEvent protocol
enum GameEvent: EmittableEvent {
  case playerDied
}
GameEvent.playerDied.emit()
```

## Dialog Trees

Screenplay-style dialog trees.

```swift
// Define speakers
let Guard = Speaker("Guard")
let Merchant = Speaker("Merchant")

// Create dialogs with branches
Dialog(id: "guard") {
  Branch("main") {
    Guard ~ "Halt! The path ahead is dangerous."

    Choice("I can handle it.") {
      Guard ~ "Ha! I like your spirit!"
    }

    Choice("Any tips?") {
      Guard ~ "Watch for patterns."
      Jump("tips")  // Jump to another branch
    }

    Choice("Bye.") {
      End
    }
  }

  Branch("tips") {
    Guard ~ "Use checkpoints!"
    Guard ~ "Good luck out there."
  }
}

// Conditional choices
Choice("Pay 10 gold", when: { game.gold >= 10 }) {
  Emit("payGold", ["amount": 10])
  Merchant ~ "Thank you!"
}

// Conditional blocks - runtime evaluated
When({ game.hasKey }) {
  Guard ~ "You have the key!"
  Jump("unlocked")
}

// Per-NPC state via DialogState
func makeDialog(state: DialogState) -> DialogDefinition {
  Dialog(id: "guard") {
    Branch("main") {
      When({ state.isFirstVisit }) {
        Guard ~ "Welcome, stranger!"
      }
      When({ state.visitCount > 1 }) {
        Guard ~ "Back again?"
      }
    }
  }
}

// Create dialog state (track visit counts in your game state)
let state = DialogState(visitCount: myGameState.getVisitCount(for: "guard"))

// Run dialog
let runner = DialogRunner(dialog: myDialog)
runner.onLine = { line in print("\(line.speaker): \(line.text)") }
runner.onChoices = { choices in /* show UI */ }
runner.onEnd = { /* close dialog */ }
runner.start()
runner.advance()           // Next line
runner.selectChoice(0)     // Pick choice

// Handle Emit() events
.onEvent(DialogBusEvent.self) { _, event in
  if case .emitted(let name, let data) = event, name == "payGold" {
    player.gold -= data?["amount"] as? Int ?? 0
  }
}
```

## Node Modifiers

### Control Layout

```swift
// Anchor/offset presets (non-container parents)
Control$()
  .anchors(.center)
  .offsets(.topRight)
  .anchorsAndOffsets(.fullRect, margin: 10)
  .anchor(top: 0, right: 1, bottom: 1, left: 0)
  .offset(top: 12, right: -12, bottom: -12, left: 12)

// Container size flags (for VBox/HBox parents)
Button$()
  .sizeH(.expandFill)
  .sizeV(.shrinkCenter)
  .size(.expandFill, .shrinkCenter)
  .size(.expandFill)  // Both axes
```


### Theme Building

```swift
// Flat dictionary - auto-categorized by property name
Label$()
  .theme(Theme([
  "Label": [
    "colors": ["fontColor": Color.white],
    "fontSizes": ["fontSize": 16]
  ]
]))

// Or create and reuse a Theme
let theme = Theme([
  "Label": [
    "colors": ["fontColor": Color.white],
    "fontSizes": ["fontSize": 16]
  ]
])

Control$().theme(theme)
```

### StyleBox Styling

Declarative StyleBox builders for UI styling.

```swift
// StyleBoxFlat$ - for solid colors, borders, shadows
PanelContainer$ {
  Label$().text("Styled Panel")
}
.panelStyle(
  StyleBoxFlat$()
    .bgColor(.black.withAlpha(0.9))
    .borderColor(.cyan)
    .borderWidth(2)
    .cornerRadius(8)
    .shadowColor(.black.withAlpha(0.5))
    .shadowSize(12)
)

// Generic styleBox modifier
Control$()
  .styleBox("panel", StyleBoxFlat$().bgColor(.red))
  .styleBox("focus", StyleBoxFlat$().borderColor(.white))

#### Available StyleBox Builders

- `StyleBoxFlat$()` - Solid colors, borders, rounded corners, shadows
- `StyleBoxTexture$(texture:)` - Texture-based styling
- `StyleBoxLine$()` - Simple line/border styling
- `StyleBoxEmpty$()` - Invisible (no background)

#### Convenience Methods (StyleBoxFlat$ only)

- `.borderWidth(_:)` - Sets all 4 border widths
- `.cornerRadius(_:)` - Sets all 4 corner radii
- `.contentMargin(_:)` - Sets all 4 content margins
- `.expandMargin(_:)` - Sets all 4 expand margins

### Collision (2D)

Named layer helpers.

```swift
CharacterBody2D$()
  .collisionLayer(.alpha)
  .collisionMask([.beta, .gamma])

// Available layers: .alpha, .beta, .gamma, .delta, .epsilon, .zeta, .eta, .theta,
// .iota, .kappa, .lambda, .mu, .nu, .xi, .omicron, .pi, .rho, .sigma, .tau,
// .upsilon, .phi, .chi, .psi, .omega

// Custom layers
CharacterBody2D$()
  .collisionMask(wallLayer | enemyLayer)
```


### Groups

```swift
Node2D$()
  .group("enemies")
  .group("damageable", persistent: true)
  .groups(["enemies", "damageable"])
```

### Scene Instancing
```swift
Node2D$()
  .fromScene("enemy.tscn") { child in
    // Configure instanced scene
  }
```

## Extensions

### Vector2 Extensions

```swift
let pos = Vector2(100, 200)
let pos: Vector2 = [100, 200]  // Array literal
let doubled = pos * 2
let scaled = pos * 1.5
```

### Color Extensions

```swift
// Create colors with alpha
let semiTransparent = Color.black.withAlpha(0.9)
let glowColor = Color.cyan.withAlpha(0.5)

### Shape Extensions

```swift
let rect = RectangleShape2D(w: 50, h: 100)
let circle = CircleShape2D(radius: 25)
let capsule = CapsuleShape2D(radius: 10, height: 50)
let segment = SegmentShape2D(a: [0, 0], b: [100, 100])
let ray = SeparationRayShape2D(length: 100)
let boundary = WorldBoundaryShape2D(normal: [0, -1], distance: 0)
```

### Node Extensions

```swift
// Typed queries
let sprites: [Sprite2D] = node.getChildren()
let firstSprite: Sprite2D? = node.getChild()
let enemySprite: Sprite2D? = node.getNode("Enemy")

// Group queries
let enemies: [Enemy] = node.getNodes(inGroup: "enemies")

// Parent chain
let parents: [Node2D] = node.getParents()

// Metadata queries (recursive)
let spawns: [Node2D] = root.queryMeta(key: "type", value: "spawn")
let valuable: [Node2D] = root.queryMeta(key: "value", value: 100)
let markers: [Node2D] = root.queryMetaKey("marker")

// Get typed metadata
let coinValue: Int? = node.getMetaValue("coin_value")
```

### Engine Extensions

```swift
if let tree = Engine.getSceneTree() {
  // ...
}

Engine.onNextFrame {
  print("Next frame!")
}

Engine.onNextPhysicsFrame {
  print("Next physics frame!")
}
```

## Helpers

### SpriteSheet

Reference individual sprites from a spritesheet by name.

```swift
enum ItemSprite: Int, SpriteSheet {
  case heart = 0
  case key = 1
  // tile 2 blank
  case coin = 3, coinSide = 13, coinBack = 23
  case sword = 4

  static let sheetPath = "res://items.png"
  static let tileSize: Vector2 = [16, 16]
  static let columns = 10

  // Define animations
  static let coinSpin = SpriteAnimation(frames: [.coin, .coinSide, .coinBack, .coinSide], fps: 4)
}

// Static sprite
Sprite2D$().texture(ItemSprite.heart.texture)

// Animated sprite (uses Godot's AnimatedSprite2D)
AnimatedSpriteSheet(ItemSprite.coinSpin)
```

### Particle Effects

```swift
// Define presets as extensions
extension ParticleConfig {
  static let explosion = ParticleConfig(
    amount: 20,
    lifetime: 0.8,
    explosiveness: 1.0,
    direction: Vector2(x: 0, y: -1),
    spread: 180,
    initialVelocityMin: 100,
    initialVelocityMax: 200,
    gravity: Vector2(x: 0, y: 400),
    color: Color(r: 1.0, g: 0.5, b: 0.0)
  )
}

// Apply to particles
let config = ParticleConfig.explosion
CPUParticles2D$()
  .amount(config.amount)
  .lifetime(config.lifetime)
  .explosiveness(config.explosiveness)
  .direction(config.direction)
  .spread(config.spread)
  .initialVelocityMin(config.initialVelocityMin)
  .initialVelocityMax(config.initialVelocityMax)
  .gravity(config.gravity)
  .color(config.color)
```

### Input Actions

```swift
// Define actions
Actions {
  Action("jump") {
    Key(.space)
    JoyButton(.a, device: 0)
  }

  Action("shoot") {
    MouseButton(1)
    Key(.leftCtrl)
  }

  // Analog axes
  ActionRecipes.axisUD(
    namePrefix: "move",
    device: 0,
    axis: .leftY,
    dz: 0.2,
    keyDown: .s,
    keyUp: .w
  )

  ActionRecipes.axisLR(
    namePrefix: "move",
    device: 0,
    axis: .leftX,
    dz: 0.2,
    keyLeft: .a,
    keyRight: .d
  )
}
.install(clearExisting: true)

// Runtime polling
if Action("jump").isJustPressed {
  player.jump()
}

if Action("shoot").isPressed {
  player.shoot(Action("shoot").strength)
}

let horizontal = RuntimeAction.axis(negative: "move_left", positive: "move_right")
let movement = RuntimeAction.vector(
  negativeX: "move_left",
  positiveX: "move_right",
  negativeY: "move_up",
  positiveY: "move_down"
)
```

### Combat Helpers

Melee weapon timing with startup/active/recovery phases.

```swift
let sword = WeaponConfig(
  name: "Sword",
  hitboxSize: [8, 8],
  hitboxOffset: 7,
  startupTime: 0.05,
  activeTime: 0.1,
  recoveryTime: 0.1,
  damage: 1,
  knockback: 80,
  canHitMultiple: false,
  sweepArc: nil
)

var phase: AttackPhase = .idle
var timer = 0.0

func startAttack() {
  phase = .startup
  timer = sword.startupTime
}

func update(delta: Double) {
  timer -= delta
  if timer <= 0 {
    phase = phase.next()
    timer = phase.duration(weapon: sword)
  }
  if phase.hitboxActive { /* deal damage */ }
}
```

### MsgLog

Thread-safe logging singleton.

```swift
MsgLog.shared.debug("Debug message")
MsgLog.shared.info("Info message")
MsgLog.shared.warn("Warning")
MsgLog.shared.error("Error")

// Set minimum level
MsgLog.shared.minLevel = .warn

// Custom sink
MsgLog.shared.sink = { level, message in
  print("[\(level)] \(message)")
}
```

## Integrations

### LDtk

Complete workflow for loading LDtk levels and bridging enums.

```swift
// Define type-safe enums matching LDtk enum values
enum Item: String, LDEnum {
  case knife = "Knife"
  case boots = "Boots"
  case potion = "Potion"
}

struct GameView: GView {
  let project: LDProject
  @State var inventory: [Item] = []
  @State var spawnPosition: Vector2 = .zero

  var body: some GView {
    Node2D$ {
      LDLevelView(project, level: "Level_0")
        // Spawn nodes for entities
        .onEntitySpawn("Player") { entity, level, project in
          // Collision layers from LDtk
          let wallLayer = project.collisionLayer(for: "walls", in: level)
          // Typed fields
          let startItems: [Item] = entity.field("starting_items")?.asEnumArray() ?? []
          inventory.append(contentsOf: startItems)

          return CharacterBody2D$ {
            Sprite2D$()
              .res(\.texture, "player.png")
              .anchor([16, 22], within: entity.size, pivot: entity.pivotVector)
            CollisionShape2D$()
              .shape(RectangleShape2D(w: 16, h: 22))
          }
          .position(entity.positionCenter)
          .collisionMask(wallLayer)
        }
        // Side effects only (no node spawned)
        .onEntity("Enemy") { entity, _, _ in
          enemySpawnPosition = entity.positionCenter
        }
        // Post-process all spawned entities
        .onSpawned { entity, node in
          node.addChild(node: Label$().text(entity.identifier).toNode())
        }
    }
  }
}

// Usage
let project = try! LDProject.load(path: "res://game.ldtk")
addChild(node: GameView(project: project).toNode())
```

#### Reactive Level Switching

```swift
// Level changes automatically rebuild the view
LDLevelView(project, level: $state.currentLevelId)
  .onEntitySpawn("Player") { entity, level, project in
    PlayerView(entity: entity)
  }
```

#### LDtk Field Accessors

All LDtk field types are supported:

```swift
// Single values
entity.field("health")?.asInt() -> Int?
entity.field("speed")?.asDouble() -> Double?
entity.field("speed")?.asFloat() -> Float?
entity.field("locked")?.asBool() -> Bool?
entity.field("name")?.asString() -> String?
entity.field("tint")?.asColor() -> Color?
entity.field("destination")?.asPoint() -> LDPoint?
entity.field("spawn_pos")?.asVector2(gridSize: 16) -> Vector2?
entity.field("target")?.asEntityRef() -> LDEntityRef?
entity.field("item_type")?.asEnum<Item>() -> Item?

// Arrays
entity.field("scores")?.asIntArray() -> [Int]?
entity.field("distances")?.asDoubleArray() -> [Double]?
entity.field("distances")?.asFloatArray() -> [Float]?
entity.field("flags")?.asBoolArray() -> [Bool]?
entity.field("tags")?.asStringArray() -> [String]?
entity.field("waypoints")?.asPointArray() -> [LDPoint]?
entity.field("patrol")?.asVector2Array(gridSize: 16) -> [Vector2]?
entity.field("palette")?.asColorArray() -> [Color]?
entity.field("targets")?.asEntityRefArray() -> [LDEntityRef]?
entity.field("loot")?.asEnumArray<Item>() -> [Item]?
entity.field("values")?.asArray() -> [LDFieldValue]?  // Raw array
```

#### LDtk Collision Helper

```swift
// Get physics layer bit for IntGrid group name
let wallLayer = project.collisionLayer(for: "walls", in: level)
let platformLayer = project.collisionLayer(for: "platforms", in: level)

CharacterBody2D$()
  .collisionMask(wallLayer | platformLayer)
```

#### Tile Layer Handlers

Override default tile layer rendering with custom handlers.

```swift
LDLevelView(project, level: "Level_0")
  .onTileLayerSpawn("Breakable") { layer, level, project in
    LDBreakableTerrainView(layer: layer, project: project)
      .terrainCollisionLayer(.terrain)
      .detectionMask(.combat)
      .onTileDestroyed { position in
        GameEvent.terrainDestroyed(position: position).emit()
      }
  }
```

#### LDIntGridZonesView

Build Area2D collision zones from IntGrid values with identifiers.

```swift
LDIntGridZonesView(layer: hazardLayer, project: project)
  .collisionLayer(.hazard)
  .collisionMask(.player)
  .onZoneEnter { zone, body in
    if zone.identifier == "damage" {
      GameEvent.playerHit(damage: 1).emit()
    }
  }
  .onZoneExit { zone, body in
    // Handle exit
  }
```

#### LDBreakableTerrainView

Tile layer where tiles can be destroyed by collision.

```swift
LDBreakableTerrainView(layer: breakableLayer, project: project)
  .terrainCollisionLayer(.terrain)
  .detectionLayer(.none)
  .detectionMask(.combat)
  .onTileDestroyed { position in
    GameEvent.terrainDestroyed(position: position).emit()
  }
```

### SVGSprite

Runtime SVG rendering with vertex manipulation effects.

```swift
// Basic usage
SVGSprite$()
  .path("icon.svg")
  .size(16) // Default is 32
  .colors([.red, .darkRed, .crimson]) // Per-element colors
  .stroke(.white, width: 2)

// Mixing effect types - chaining works fine
SVGSprite$()
  .colorCycle([.red, .orange, .yellow]) // color effect
  .inflate(amount: 3.0)                 // vertex effect

// Multiple vertex effects - use svgEffects builder
SVGSprite$()
  .path("icon.svg")
  .svgEffects {
    SVGInflate(amount: 3.0)                    // applied first
    SVGNoise(amount: 1.5)                      // applied to inflated result
  }

// With reactive bindings
@State var meltProgress: Double = 0

SVGSprite$()
  .path("enemy.svg")
  .melt(progress: $meltProgress)  // Animate on death
```

#### Color Effects

Can be freely chained with each other and with vertex effects.

`.pulse(speed, amplitude, baseSize)`, `.colorCycle(colors, speed)`, `.strokeCycle(colors, speed)`, `.dualColorCycle(fill:, stroke:)`

#### Vertex Effects

Modify vertex positions. Use `svgEffects { }` to combine multiple.

`.wobble(amount, speed)`, `.inflate(amount, speed)`, `.skew(amount, speed, animated)`, `.noise(amount, speed)`, `.ripple(amplitude, frequency, speed)`, `.twist(amount, speed)`, `.wave(amplitude, frequency, speed)`, `.explode(progress, scale)`, `.scatter(progress, scale, rotate)`, `.melt(progress, scale, waviness)`

### AseSprite

```swift
// Load Aseprite animations
let sprite = AseSprite(
  "character.json",
  layer: "Body",
  options: .init(
    timing: .delaysGCD,
    trimming: .applyPivotOrCenter
  ),
  autoplay: "Idle"
)

// Builder pattern
AseSprite$(path: "player", layer: "Main")
  .configure { sprite in
    sprite.play(anim: "Walk")
  }
```

### Bfxr

Real-time synthesis of retro sound effects from [`.bfxr`](https://www.bfxr.net) files.

```swift
// Basic sound playback
BfxrSound$("res://sounds/jump.bfxr")
  .onReady { node in
    node.playSound()
  }

// With reactive bindings
struct GameView: GView {
  @State var pitch: Double = 1.0

  var body: some GView {
    Node2D$ {
      BfxrSound$("res://sounds/laser.bfxr")
        .ref($laserSound)
        .frequencyStart($pitch)
    }
  }
}
```

## Scenes & Transitions

### SceneRouter

Vue Router-inspired navigation with built-in transitions.

```swift
enum GameScene { case splash, menu, playing, gameOver }

@ObservableState var router = SceneRouter(initial: GameScene.splash)

// Navigate with transitions
router.navigate(to: .menu, transition: .fade())
router.navigate(to: .playing, transition: .wipe(duration: 0.5))
router.navigate(to: .gameOver, transition: .iris(center: playerPos))

// With midpoint callback for setup
router.navigate(to: .playing, transition: .fade()) {
  state.reset()
  state.currentLevel = selectedLevel
}

// Use with Switch for reactive UI
Switch($router.scene) {
  Case(.splash) { SplashOverlay() }
  Case(.menu) { MainMenu() }
  Case(.playing) { GameLevel() }
  Case(.gameOver) { GameOverScreen() }
}
.mode(.destroy)

// Pass router's transition state to TransitionManager
TransitionManager(state: $router.transitionState, screenSize: [428, 240])

// Nested routes (child routers)
let levelRouter = router.child(for: .playing, initial: 1)
levelRouter.navigate(to: 3, transition: .fade())
```

### Transitions

- **fade** - Screen fades to black and back
- **wipe** - Horizontal wipe across screen
- **irisOut** - Circle shrinks to point, then expands

```swift
struct GameUI: GView {
  @ObservableState var transitionState = TransitionState()

  var body: some GView {
    CanvasLayer$ {
      // Game UI here
    }

    TransitionManager(state: $transitionState, screenSize: [428, 240])
  }
}

// Simple fade
transitionState.fadeTransition(onMidpoint: {
  loadNextLevel()
})

// Wipe with custom duration
transitionState.wipeTransition(duration: 0.8)

// Iris centered on player
let playerCenter: Vector2 = [0.3, 0.6] // normalized 0-1
transitionState.irisOutTransition(center: playerCenter)

// Hold at midpoint for minimum duration
transitionState.fadeTransition(holdDuration: 0.5, onMidpoint: {
  loadLevel()
})

// Wait for async work to complete
transitionState.fadeTransition(waitForResume: true, onMidpoint: {
  loadLevelAsync {
    transitionState.resume() // Continue transition when ready
  }
})

// Both: minimum hold time + wait for async
transitionState.irisOutTransition(
  holdDuration: 0.3,
  waitForResume: true,
  onMidpoint: { startLoading() },
  onComplete: { print("Done!") }
)
```

#### Transition Events

```swift
.onEvent(TransitionEvent.self) { _, event in
  switch event {
  case .started(let type): print("Started \(type)")
  case .midpoint: print("Midpoint reached")
  case .completed(let type): print("Completed \(type)")
  }
}
```

## Object Pools

### ObjectPool

Generic pool for reusable Godot objects.

```swift
final class Bullet: Node2D, PooledObject {
  func onAcquire() { visible = true }
  func onRelease() { visible = false; position = .zero }
}

let pool = ObjectPool<Bullet>(factory: { Bullet() })
pool.preload(64)

if let bullet = pool.acquire() {
  bullet.position = spawnPos
  parent.addChild(node: bullet)
  // later:
  pool.release(bullet)
}

// Or use PoolLease for scoped usage
PoolLease(pool).using { bullet in
  // automatically released after closure
}
```

### AreaPool

Pool for Area2D projectiles with velocity-based movement.

```swift
let bulletPool = AreaPool(
  preload: 30,
  speed: 300,
  lifetime: 3.0,
  bounds: (-50, 850, -50, 290)
) {
  Area2D$ {
    Sprite2D$().res(\.texture, "bullet.png")
    CollisionShape2D$().shape(CircleShape2D(radius: 4))
  }
  .collisionLayer(.beta)
  .collisionMask(.alpha)
}

// Call once when parent is in scene tree
bulletPool.start()

// Fire projectiles
bulletPool.fire(at: playerPos, direction: aimDir, parent: self)

// Update in _process
bulletPool.update(delta: delta)
```

### TypedParticlePool

Multi-variant particle pool keyed by type.

```swift
enum ParticleType { case dust, spark, blood }

let particles = TypedParticlePool<ParticleType, CPUParticles2D>(
  keys: [.dust, .spark, .blood],
  config: .init(prewarmPerType: 5)
) { type in
  switch type {
  case .dust: return makeDustParticles()
  case .spark: return makeSparkParticles()
  case .blood: return makeBloodParticles()
  }
}

particles.setup(parent: self)
particles.spawn(type: .dust, at: position)
particles.spawn(type: .spark, at: hitPoint, scale: [2, 2])
```

## Tweens

```swift
// One-shot tween
btn.tween(.scale([1.1, 1.1]), duration: 0.1)
   .ease(.out).trans(.quad)

// Fade out and remove
enemy.tween(.alpha(0.0), duration: 0.3)
   .onFinished { enemy.queueFree() }

// Managed tween (kills previous)
@State var currentTween: TweenHandle?

currentTween = btn.tween(.scale([1.1, 1.1]), duration: 0.1, killing: currentTween)
   .trans(.quad).ease(.out)
```

#### Sequences

```swift
// Bounce effect
btn.tween { seq in
  seq.to(.scale([1.0, 0.8]), duration: 0.05)
     .trans(.quad).ease(.out)
     .to(.scale([1.0, 1.15]), duration: 0.08)
     .trans(.quad).ease(.out)
     .to(.scale([1.0, 1.0]), duration: 0.12)
     .trans(.bounce).ease(.out)
}

// Looping pulse
icon.tween { seq in
  seq.to(.scale([1.05, 1.05]), duration: 0.5)
     .trans(.sine).ease(.inOut)
     .to(.scale([1.0, 1.0]), duration: 0.5)
     .trans(.sine).ease(.inOut)
}
.loop()

// Loop specific number of times
node.tween { seq in
  seq.to(.rotation(Float.pi * 2), duration: 1.0)
}
.loop(3)
```

#### Available Anim Properties

- **Scale**: `.scale(Vector2)`, `.scaleX(Float)`, `.scaleY(Float)`
- **Position**: `.position(Vector2)`, `.positionX(Float)`, `.positionY(Float)`, `.globalPosition(Vector2)`
- **Rotation**: `.rotation(Float)`, `.rotationDegrees(Float)`
- **Color**: `.modulate(Color)`, `.alpha(Float)`, `.selfModulate(Color)`, `.selfAlpha(Float)`
- **Size**: `.size(Vector2)`, `.minSize(Vector2)`, `.pivotOffset(Vector2)`
- **Other**: `.skew(Float)`, `.volumeDb(Float)`, `.pitchScale(Float)`
- **Custom**: `.custom(property: String, value: Variant)`

#### Reactive Tween Modifiers

Animate properties in response to state changes.

```swift
// Toggle animation - animate between two values based on bool state
@State var isHovered = false

Button$()
  .tweenToggle($isHovered, Anim.Scale.self,
               whenTrue: [1.1, 1.1], whenFalse: [1.0, 1.0],
               duration: 0.1)
  .onSignal(\.mouseEntered) { _ in isHovered = true }
  .onSignal(\.mouseExited) { _ in isHovered = false }

// Conditional animation - run different animations based on state value
@State var selectedTab = 0

TabButton$()
  .tweenWhen($selectedTab, equals: 0) { btn in
    btn.tween(.scale([1.1, 1.1]), duration: 0.1).ease(.out)
  } otherwise: { btn in
    btn.tween(.scale([1.0, 1.0]), duration: 0.1).ease(.out)
  }

// On change - custom handler for any state change
@State var health = 100

HealthBar$()
  .tweenOnChange($health) { bar, newHealth in
    bar.tween(.scaleX(Float(newHealth) / 100.0), duration: 0.2).ease(.out)
  }
```

## Built-in Views

### Layout

```swift
Spacer(16)      // Fixed height spacer
SpacerV()       // Vertical expand-fill
SpacerH()       // Horizontal expand-fill
```

### Buttons

```swift
StyledButton("Play", width: 80, color: .cyan) { startGame() }
AnimatedButton("Start", color: .green) { play() }  // Hover/press animations
BounceButton("Jump", color: .yellow) { jump() }    // Bounce on press
```

### Labels

```swift
HeaderLabel("Game Over", size: 24, color: .red)
InfoLabel("Press any key", color: .gray)
LiveInfoLabel(state.scoreDisplay, color: .gold)  // Reactive text
```

### ColorBox

Polygon2D-based colored rectangle (like ColorRect for outside the UI).

```swift
ColorBox$([100, 50])
  .color(.red)
  .position([200, 300])
```

### AudioManager

Syncs volume settings with AudioServer.

```swift
AudioManager(settings: $settings) {
  BfxrSound$().bfxrPath("sounds/Jump.bfxr")
}
```

### Overlays

```swift
// Scrolling BBCode credits with star particles
CreditsOverlay(
  isVisible: $showCredits,
  creditsText: "[center][color=#00FFFF]My Game[/color]..."
) {
  showCredits = false
}

// Animated title with "press any button" prompt
SplashOverlay(
  isVisible: $showSplash,
  title: "My Game",
  prompt: "PRESS START"
) {
  showSplash = false
}

// Typewriter text with choice buttons
DialogBox(
  isVisible: $showDialog,
  dialogRunner: { myDialogRunner },
  speakerColors: ["Hero": .cyan, "Villain": .red]
) {
  showDialog = false
}
```

### Spawners

```swift
// Damage numbers, popups
FloatingTextSpawner(GameEvent.self) { event in
  if case let .damageDealt(amount, position) = event {
    return (text: "\(amount)", position: position, color: .red)
  }
  return nil
}

// Spawn nodes in response to events
NodeSpawner(GameEvent.self) { event in
  if case let .collectibleSpawned(def, pos) = event {
    return CollectibleView(position: pos, def).toNode()
  }
  return nil
} resetWhen: { event in
  if case .gameReset = event { return true }
  return false
}
```

## Utilities

### Palette

Shared color/style definitions.

```swift
let palette = Palette.shared
palette.cyan, palette.red, palette.gold
palette.buttonStyles(palette.cyan, withFocus: true)
palette.panelStyle, palette.victoryPanelStyle
```

### UserSettings

Persistable audio/display settings.

```swift
let settings = UserSettings()  // Auto-loads from disk
settings.masterVolume, settings.sfxVolume, settings.musicVolume
settings.masterVolumeDisplay  // "70%"
```

## Property Wrappers

For imperative `@Godot` classes - add `bindProps()` in `_ready()` to activate property wrappers.

```swift
@Godot
final class Player: CharacterBody2D {
  @Child("Sprite") var sprite: Sprite2D?
  @Child("Health", deep: true) var healthBar: ProgressBar?
  @Children var buttons: [Button]
  @Ancestor var level: Level?
  @Sibling("AudioPlayer") var audio: AudioStreamPlayer?
  @Autoload("GameManager") var gameManager: GameManager?
  @Group("enemies") var enemies: [Enemy]
  @Service var events: EventBus<GameEvent>?
  @Prefs("musicVolume", default: 0.5) var volume: Double

  @OnSignal("StartButton", \Button.pressed)
  func onStartPressed(_ sender: Button) {
    print("Started!")
  }

  override func _ready() {
    bindProps()

    sprite?.visible = true
    enemies.forEach { print($0) }

    // Refresh group query
    let currentEnemies = $enemies()
  }
}
```
