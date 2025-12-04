
============================================================================
LDTK SETUP INSTRUCTIONS
============================================================================
 CREATE YOUR LDTK PROJECT
   - Create a new project and save it in your GodotProject/ folder
 CONFIGURE LEVEL
  - Add these fields to your Level settings for metadata:
    - "displayName" (String) - Human-readable level name
    - "totalCoins" (Int) - Number of coins in the level
    - "goldTime" (Float) - Time in seconds for gold medal
    - "silverTime" (Float) - Time in seconds for silver medal
    - "bronzeTime" (Float) - Time in seconds for bronze medal
 DEFINE YOUR TILESETS
   - In LDtk, go to Tilesets (T)
   - Import your tileset PNG images (put them in GodotProject/ so paths are relative)
   - Add a Tiles layer
 CREATE INTGRID LAYERS FOR COLLISION
   - Add an IntGrid layer (e.g., "Collision")
   - Define values like:
     - 1 = Solid (walls/platforms)
     - 2 = OneWay (jump-through platforms)
     - 3 = Hazard (spikes/lava)
 DESIGN YOUR LEVELS
   - Create levels in LDtk (Level_0, Level_1, etc.)
   - Paint tiles on your tileset layers
   - Paint collision on IntGrid layers
 CREATE ENUMS FOR TYPE-SAFE DATA
   - Build project to generate LDExported.json from your LDExported enums
     - Run copy-ldtk-enums.sh to copy it to GodotProject/
   - In Project Settings > Enums:
     - Click Import
     - Select LDExported.json from GodotProject/
     - LDtk will sync enums with this file
 DEFINE YOUR ENTITIES
   - In Project Settings > Entities, create:
     - PlayerSpawn
     - NPCSpawn
     - EnemySpawn
     - BossSpawn
     - Collectible
     - Platform
     - Trigger
     - Hazard
     - Crusher

 DESIGN YOUR LEVELS (CONTINUED)
   - Create entity layer & place entities in your levels
============================================================================

