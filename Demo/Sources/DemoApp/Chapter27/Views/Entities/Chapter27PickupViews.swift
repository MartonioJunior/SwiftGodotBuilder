import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  // MARK: - Generic Pickup View

  /// Generic pickup view - renders any Pickupable item
  struct PickupView<T: Pickupable>: GView {
    let position: Vector2
    let item: T
    let onCollected: (T) -> Void

    var body: some GView {
      Area2D$ {
        AseSprite$(path: item.sprite)
          .autoplay(item.animation)
          .centered(false)

        CollisionShape2D$()
          .shape(RectangleShape2D(size: item.size + [1, 1]))
          .position(item.size / 2)
      }
      .position(position)
      .collisionLayer(.collectible)
      .collisionMask(.interaction)
      .onSignal(\.areaEntered) { node, _ in
        onCollected(item)
        node.queueFree()
      }
    }
  }

  // MARK: - Consumable Pickup View

  /// Collectible entity from LDtk (consumables only)
  struct ConsumablePickupView: GView {
    let position: Vector2
    let consumable: ConsumableDefinition

    init(entity: LDEntity) {
      let type: ConsumableType = entity.field("type")?.asEnum() ?? .coin
      consumable = type.definition
      position = entity.positionTopLeft
    }

    init(position: Vector2, consumable: ConsumableDefinition) {
      self.position = position
      self.consumable = consumable
    }

    var body: some GView {
      PickupView(position: position, item: consumable) { item in
        GameEvent.consumableCollected(item, position: position).emit()
      }
    }
  }

  // MARK: - Weapon Pickup View

  /// WeaponPickup entity from LDtk
  struct WeaponPickupView: GView {
    let position: Vector2
    let weapon: ActorWeapon

    init?(entity: LDEntity) {
      guard let weaponId = entity.field("weaponId")?.asString(),
            let weapon = WeaponRegistry.weapon(forId: weaponId)
      else {
        return nil
      }
      position = entity.positionTopLeft
      self.weapon = weapon
    }

    init(position: Vector2, weapon: ActorWeapon) {
      self.position = position
      self.weapon = weapon
    }

    var body: some GView {
      PickupView(position: position, item: weapon) { weapon in
        GameEvent.weaponCollected(weapon, position: position).emit()
      }
    }
  }

  // MARK: - Ammo Pickup View

  /// AmmoPickup entity from LDtk - weapon-specific ammo
  struct AmmoPickupView: GView {
    let position: Vector2
    let weapon: ActorWeapon
    let amount: Int

    init?(entity: LDEntity) {
      guard let weaponId = entity.field("weaponId")?.asString(),
            let weapon = WeaponRegistry.weapon(forId: weaponId)
      else {
        return nil
      }
      position = entity.positionTopLeft
      self.weapon = weapon
      amount = entity.field("amount")?.asInt() ?? weapon.ammoPerPickup
    }

    init(position: Vector2, weapon: ActorWeapon, amount: Int? = nil) {
      self.position = position
      self.weapon = weapon
      self.amount = amount ?? weapon.ammoPerPickup
    }

    private var ammoSprite: String { weapon.ammoSprite ?? weapon.pickupSprite ?? "Items" }
    private var ammoAnimation: String { weapon.ammoAnimation ?? "orbSilver" }

    var body: some GView {
      Area2D$ {
        AseSprite$(path: ammoSprite)
          .autoplay(ammoAnimation)
          .centered(false)

        CollisionShape2D$()
          .shape(RectangleShape2D(size: [8, 8]))
          .position([4, 4])
      }
      .position(position)
      .collisionLayer(.collectible)
      .collisionMask(.interaction)
      .onSignal(\.areaEntered) { node, _ in
        GameEvent.ammoCollected(weapon: weapon, amount: amount, position: position).emit()
        node.queueFree()
      }
    }
  }
}
