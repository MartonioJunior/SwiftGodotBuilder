import Foundation
import SwiftGodot

// MARK: - Weapon Definition

/// A weapon that any actor can use - melee or ranged
public struct ActorWeapon: Equatable, Sendable {
  public let id: String
  public let type: ActorWeaponType
  public let spriteLayer: String?

  // Melee configuration
  public var melee: ActorMeleeConfig?

  // Ranged configuration
  public var ranged: ActorRangedConfig?

  // Ammo settings
  public var maxAmmo: Int
  public var ammoPerPickup: Int
  public var infiniteAmmo: Bool

  // Pickup metadata (nil pickupSprite = cannot be picked up, e.g. enemy-only weapons)
  public var pickupSprite: String?
  public var pickupAnimation: String?
  public var pickupSize: Vector2
  public var ammoSprite: String?
  public var ammoAnimation: String?

  public init(
    id: String,
    type: ActorWeaponType,
    spriteLayer: String? = nil,
    melee: ActorMeleeConfig? = nil,
    ranged: ActorRangedConfig? = nil,
    maxAmmo: Int = 0,
    ammoPerPickup: Int = 5,
    infiniteAmmo: Bool = false,
    pickupSprite: String? = nil,
    pickupAnimation: String? = nil,
    pickupSize: Vector2 = [8, 8],
    ammoSprite: String? = nil,
    ammoAnimation: String? = nil
  ) {
    self.id = id
    self.type = type
    self.spriteLayer = spriteLayer
    self.melee = melee
    self.ranged = ranged
    self.maxAmmo = maxAmmo
    self.ammoPerPickup = ammoPerPickup
    self.infiniteAmmo = infiniteAmmo
    self.pickupSprite = pickupSprite
    self.pickupAnimation = pickupAnimation
    self.pickupSize = pickupSize
    self.ammoSprite = ammoSprite
    self.ammoAnimation = ammoAnimation
  }

  public var isPickupable: Bool { pickupSprite != nil }
  public var usesAmmo: Bool { maxAmmo > 0 && !infiniteAmmo }

  public static func == (lhs: ActorWeapon, rhs: ActorWeapon) -> Bool {
    lhs.id == rhs.id
  }
}

// MARK: - Weapon State

/// Observable state for an actor's weapons
@Observable
public class ActorWeaponState {
  public var weapons: [ActorWeapon] = []
  public var currentIndex = 0
  public var ammo: [String: Int] = [:]

  // Attack phase (shared across weapons)
  public var phase: ActorAttackPhase = .idle
  public var phaseTimer: Double = 0

  public init(weapons: [ActorWeapon] = []) {
    self.weapons = weapons
    // Initialize ammo for weapons that use it
    for weapon in weapons {
      if weapon.maxAmmo > 0 {
        ammo[weapon.id] = weapon.maxAmmo
      }
    }
  }

  // MARK: - Current Weapon

  public var currentWeapon: ActorWeapon? {
    guard currentIndex >= 0, currentIndex < weapons.count else { return nil }
    return weapons[currentIndex]
  }

  public var hasWeapon: Bool { !weapons.isEmpty }

  public var currentAmmo: Int {
    guard let weapon = currentWeapon else { return 0 }
    return ammo[weapon.id] ?? 0
  }

  public var currentMaxAmmo: Int {
    currentWeapon?.maxAmmo ?? 0
  }

  // MARK: - Weapon Switching

  public func switchToNext() {
    guard weapons.count > 1 else { return }
    currentIndex = (currentIndex + 1) % weapons.count
  }

  public func switchToPrevious() {
    guard weapons.count > 1 else { return }
    currentIndex = (currentIndex - 1 + weapons.count) % weapons.count
  }

  public func switchTo(weaponId: String) -> Bool {
    guard let index = weapons.firstIndex(where: { $0.id == weaponId }) else { return false }
    currentIndex = index
    return true
  }

  public func addWeapon(_ weapon: ActorWeapon) {
    guard !weapons.contains(weapon) else { return }
    weapons.append(weapon)
    if weapon.maxAmmo > 0 {
      ammo[weapon.id] = weapon.maxAmmo
    }
  }

  public func removeWeapon(id: String) {
    weapons.removeAll { $0.id == id }
    ammo.removeValue(forKey: id)
    if currentIndex >= weapons.count {
      currentIndex = max(0, weapons.count - 1)
    }
  }

  // MARK: - Ammo

  public func consumeAmmo() -> Bool {
    guard let weapon = currentWeapon else { return false }
    if weapon.maxAmmo == 0 { return true }
    if weapon.infiniteAmmo { return true }
    let current = ammo[weapon.id] ?? 0
    guard current > 0 else { return false }
    ammo[weapon.id] = current - 1
    return true
  }

  public func addAmmo(for weaponId: String, amount: Int) {
    guard let weapon = weapons.first(where: { $0.id == weaponId }) else { return }
    let current = ammo[weaponId] ?? 0
    ammo[weaponId] = min(current + amount, weapon.maxAmmo)
  }

  public func refillAmmo(for weaponId: String) {
    guard let weapon = weapons.first(where: { $0.id == weaponId }) else { return }
    ammo[weaponId] = weapon.maxAmmo
  }

  // MARK: - Attack State

  public func startMeleeAttack() {
    guard phase == .idle, let melee = currentWeapon?.melee else { return }
    phase = .startup
    phaseTimer = melee.startupTime
  }

  public func updateTimer(_ delta: Double) -> ActorAttackPhase? {
    guard phase != .idle, phaseTimer > 0 else { return nil }

    phaseTimer -= delta
    if phaseTimer <= 0 {
      phaseTimer = 0
      return advancePhase()
    }
    return nil
  }

  private func advancePhase() -> ActorAttackPhase {
    guard let melee = currentWeapon?.melee else {
      phase = .idle
      return .idle
    }

    switch phase {
    case .startup:
      phase = .active
      phaseTimer = melee.activeTime
      return .active

    case .active:
      phase = .recovery
      phaseTimer = melee.recoveryTime
      return .recovery

    case .recovery:
      phase = .idle
      phaseTimer = 0
      return .idle

    case .idle:
      return .idle
    }
  }

  public func reset() {
    phase = .idle
    phaseTimer = 0
    for weapon in weapons where weapon.maxAmmo > 0 {
      ammo[weapon.id] = weapon.maxAmmo
    }
  }
}

// MARK: - Weapon Events

public enum ActorWeaponEvent: EmittableEvent {
  case weaponSwitched(actorId: Int, weapon: ActorWeapon)
  case ammoChanged(actorId: Int, weaponId: String, current: Int, max: Int)
  case ammoEmpty(actorId: Int, weaponId: String)
  case weaponAcquired(actorId: Int, weapon: ActorWeapon)
}

/// Types of weapons available
public enum ActorWeaponType: Sendable {
  case unarmed
  case melee
  case ranged
}

/// Configuration for a melee weapon's hitbox and timing
public struct ActorMeleeConfig: Sendable {
  public let hitboxSize: Vector2
  public let hitboxOffset: Float
  public let startupTime: Double
  public let activeTime: Double
  public let recoveryTime: Double
  public let damage: Int
  public let knockback: Float

  public var totalDuration: Double { startupTime + activeTime + recoveryTime }

  public init(
    hitboxSize: Vector2,
    hitboxOffset: Float,
    startupTime: Double,
    activeTime: Double,
    recoveryTime: Double,
    damage: Int,
    knockback: Float
  ) {
    self.hitboxSize = hitboxSize
    self.hitboxOffset = hitboxOffset
    self.startupTime = startupTime
    self.activeTime = activeTime
    self.recoveryTime = recoveryTime
    self.damage = damage
    self.knockback = knockback
  }
}

/// Configuration for ranged attacks/projectiles
public struct ActorRangedConfig: Sendable {
  public let speed: Float
  public let damage: Int
  public let lifetime: Double
  public let size: Vector2

  /// Aseprite asset path (e.g., "Interactables")
  public let spriteAsset: String?

  /// Animation/tag name to play (e.g., "ArrowGray")
  public let spriteAnimation: String?

  /// Color for simple projectiles without sprites
  public let color: Color?

  /// Whether this projectile is owned by a player (affects collision layers)
  public let isPlayerOwned: Bool

  public init(
    speed: Float,
    damage: Int,
    lifetime: Double,
    size: Vector2,
    spriteAsset: String? = nil,
    spriteAnimation: String? = nil,
    color: Color? = nil,
    isPlayerOwned: Bool = true
  ) {
    self.speed = speed
    self.damage = damage
    self.lifetime = lifetime
    self.size = size
    self.spriteAsset = spriteAsset
    self.spriteAnimation = spriteAnimation
    self.color = color
    self.isPlayerOwned = isPlayerOwned
  }
}
