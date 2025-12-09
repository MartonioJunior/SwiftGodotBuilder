import SwiftGodot

/// Spawns nodes dynamically in response to events.
/// Generic over event type - provide extractors to determine when to spawn and reset.
public struct NodeSpawner<E: EmittableEvent>: GView {
  let eventType: E.Type
  let spawn: (E) -> Node?
  let shouldReset: (E) -> Bool

  /// Creates a NodeSpawner that listens for events and spawns nodes.
  /// - Parameters:
  ///   - eventType: The event type to listen for
  ///   - spawn: Closure that returns a Node to spawn when an event matches, or nil to ignore
  ///   - resetWhen: Closure that returns true when all spawned nodes should be removed
  public init(
    _ eventType: E.Type,
    spawn: @escaping (E) -> Node?,
    resetWhen: @escaping (E) -> Bool = { _ in false }
  ) {
    self.eventType = eventType
    self.spawn = spawn
    shouldReset = resetWhen
  }

  public var body: some GView {
    Node2D$()
      .onEvent(eventType) { node, event in
        // Check for reset first
        if shouldReset(event) {
          for child in node.getChildren() {
            child?.queueFree()
          }
          return
        }

        // Try to spawn a node
        if let newNode = spawn(event) {
          Engine.onNextFrame {
            node.addChild(node: newNode)
          }
        }
      }
  }
}
