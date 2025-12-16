import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  enum WeaponRegistry {
    // MARK: - Player Melee Weapons

    static let sword = ActorWeapon(
      id: "sword",
      type: .melee,
      spriteLayer: "Sword",
      melee: ActorMeleeConfig(
        hitboxSize: [8, 8],
        hitboxOffset: 6,
        startupTime: 0.05,
        activeTime: 0.1,
        recoveryTime: 0.15,
        damage: 1,
        knockback: 80
      ),
      pickupSprite: "Items",
      pickupAnimation: "sword1",
      pickupSize: [8, 8]
    )

    static let axe = ActorWeapon(
      id: "axe",
      type: .melee,
      spriteLayer: "Sword",
      melee: ActorMeleeConfig(
        hitboxSize: [12, 10],
        hitboxOffset: 5,
        startupTime: 0.15,
        activeTime: 0.12,
        recoveryTime: 0.25,
        damage: 2,
        knockback: 120
      ),
      pickupSprite: "Items",
      pickupAnimation: "axe1",
      pickupSize: [8, 8]
    )

    // MARK: - Player Ranged Weapons

    static let bow = ActorWeapon(
      id: "bow",
      type: .ranged,
      spriteLayer: "Bow",
      ranged: ActorRangedConfig(
        speed: 200,
        damage: 1,
        lifetime: 2.0,
        size: [8, 2],
        spriteAsset: "Interactables",
        spriteAnimation: "Arrow",
        isPlayerOwned: true
      ),
      maxAmmo: 10,
      ammoPerPickup: 5,
      pickupSprite: "Items",
      pickupAnimation: "bow1",
      pickupSize: [8, 8],
      ammoSprite: "Interactables",
      ammoAnimation: "Arrow"
    )

    // MARK: - Enemy-Only Weapons (no pickup)

    static let claws = ActorWeapon(
      id: "claws",
      type: .melee,
      spriteLayer: "Claws",
      melee: ActorMeleeConfig(
        hitboxSize: [6, 6],
        hitboxOffset: 4,
        startupTime: 0.05,
        activeTime: 0.1,
        recoveryTime: 0.15,
        damage: 1,
        knockback: 60
      )
    )

    static let bite = ActorWeapon(
      id: "bite",
      type: .melee,
      spriteLayer: nil,
      melee: ActorMeleeConfig(
        hitboxSize: [8, 8],
        hitboxOffset: 2,
        startupTime: 0.1,
        activeTime: 0.08,
        recoveryTime: 0.2,
        damage: 1,
        knockback: 40
      )
    )

    static let slam = ActorWeapon(
      id: "slam",
      type: .melee,
      spriteLayer: nil,
      melee: ActorMeleeConfig(
        hitboxSize: [16, 12],
        hitboxOffset: 4,
        startupTime: 0.3,
        activeTime: 0.15,
        recoveryTime: 0.4,
        damage: 2,
        knockback: 120
      )
    )

    static let fireball = ActorWeapon(
      id: "fireball",
      type: .ranged,
      spriteLayer: nil,
      ranged: ActorRangedConfig(
        speed: 120,
        damage: 1,
        lifetime: 3.0,
        size: [8, 8],
        color: Color(code: "#FF6600"),
        isPlayerOwned: false
      ),
      maxAmmo: 10,
      infiniteAmmo: true
    )

    static let spitProjectile = ActorWeapon(
      id: "spit",
      type: .ranged,
      spriteLayer: nil,
      ranged: ActorRangedConfig(
        speed: 80,
        damage: 1,
        lifetime: 2.0,
        size: [6, 6],
        color: Color(code: "#66FF66"),
        isPlayerOwned: false
      ),
      maxAmmo: 20,
      infiniteAmmo: true
    )

    static let bossOrb = ActorWeapon(
      id: "boss_orb",
      type: .ranged,
      spriteLayer: nil,
      ranged: ActorRangedConfig(
        speed: 100,
        damage: 1,
        lifetime: 4.0,
        size: [12, 12],
        color: Color(code: "#AA44FF"),
        isPlayerOwned: false
      ),
      maxAmmo: 50,
      infiniteAmmo: true
    )

    // MARK: - Pickupable Weapons (for LDtk lookup)

    static let pickupable: [ActorWeapon] = [sword, axe, bow]

    /// Lookup weapon by ID - used for LDtk entity spawning
    static func weapon(forId id: String) -> ActorWeapon? {
      pickupable.first { $0.id == id }
    }
  }
}
