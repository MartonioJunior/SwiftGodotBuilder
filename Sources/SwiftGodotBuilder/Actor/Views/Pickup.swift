import SwiftGodot

/// A collectible item that can be picked up by actors with a `.collector()` area.
///
/// ## Usage
/// ```swift
/// enum Item {
///   case coin(value: Int)
///   case health(amount: Int)
/// }
///
/// Pickup(.coin(value: 5)) {
///   AseSprite$(path: "Items").autoplay("coinGold")
///   CollisionShape2D$().shape(CircleShape2D(radius: 6))
/// } onCollected: { item, actorId in
///   switch item {
///   case .coin(let value): score += value
///   case .health(let amount): player.heal(amount)
///   }
/// }
/// ```
///
/// Emits `ActorEvent.collected(actorId, item, position)` for particles/sound.
public struct Pickup<T, Content: GView>: GView {
  let data: T
  let contentBuilder: () -> Content
  let onCollected: ((T, Int) -> Void)?

  public init(
    _ data: T,
    @GViewBuilder content: @escaping () -> Content,
    onCollected: ((T, Int) -> Void)? = nil
  ) {
    self.data = data
    contentBuilder = content
    self.onCollected = onCollected
  }

  public var body: some GView {
    let pickupData = data
    let handler = onCollected

    return Area2D$ {
      contentBuilder()
    }
    .collisionLayer(.lambda)
    .collisionMask(.mu)
    .onSignal(\.areaEntered) { node, collectorArea in
      guard let collectorArea else { return }
      let parents: [CharacterBody2D] = collectorArea.getParents()
      guard let actorBody = parents.first else {
        GD.pushWarning("[Pickup] Collector has no CharacterBody2D ancestor")
        return
      }
      let actorId = Int(actorBody.getInstanceId())

      // Event for particles/sound
      ActorEvent.collected(actorId: actorId, item: pickupData, position: node.globalPosition).emit()

      // Callback for gameplay logic
      handler?(pickupData, actorId)

      Engine.onNextFrame {
        node.queueFree()
      }
    }
  }
}
