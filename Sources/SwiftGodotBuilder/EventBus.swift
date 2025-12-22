import Foundation

/// A thread-safe publish/subscribe bus for in-process events.
///
/// For engine-layer or cross-cutting services (audio, input, event bus, save system).
/// Keep gameplay/domain logic on constructor injection so dependencies are explicit where
/// it matters for reasoning and tests.
///
/// ### Example
/// ```swift
/// // In a Godot node's setup:
/// bus.onEach(owner: self) { [weak self] event in
///   self?.handleEvent(event)
/// }
/// // Automatically cancelled when 'self' is deallocated
/// ```
public final class EventBus<Event> {
  /// Opaque handle used to cancel a previously registered handler.
  public typealias Token = UUID

  /// Internal handler entry with optional weak owner for automatic cleanup
  private final class Handler {
    let id: Token
    let hasOwner: Bool
    weak var owner: AnyObject?
    let callback: (Event) -> Void

    init(id: Token, owner: AnyObject?, callback: @escaping (Event) -> Void) {
      self.id = id
      hasOwner = owner != nil
      self.owner = owner
      self.callback = callback
    }

    var isAlive: Bool {
      !hasOwner || owner != nil
    }
  }

  private var handlers: [Token: Handler] = [:]
  private let lock = NSLock()

  init() {}

  /// Registers a handler with automatic cleanup when owner is deallocated.
  ///
  /// This is the preferred method for subscribing to events, as it automatically
  /// cleans up the handler when the owning object is freed.
  ///
  /// - Parameters:
  ///   - owner: The object that owns this subscription. When deallocated, the handler is removed.
  ///   - h: The handler to invoke for each event.
  /// - Returns: A token that can be used to manually cancel early if needed.
  @discardableResult
  public func onEach(owner: AnyObject, _ h: @escaping (Event) -> Void) -> Token {
    let id = UUID()
    lock.lock()
    handlers[id] = Handler(id: id, owner: owner, callback: h)
    lock.unlock()
    return id
  }

  /// Cancels a previously registered handler.
  public func cancel(_ id: Token) {
    lock.lock()
    handlers.removeValue(forKey: id)
    lock.unlock()
  }

  /// Publishes a single event to all per-event handlers.
  /// Dead handlers (whose owners have been deallocated) are automatically cleaned up.
  public func publish(_ e: Event) {
    lock.lock()

    // Collect alive handlers and track dead ones for cleanup
    var aliveHandlers: [(Event) -> Void] = []
    var deadIds: [Token] = []

    for (id, handler) in handlers {
      if handler.isAlive {
        aliveHandlers.append(handler.callback)
      } else {
        deadIds.append(id)
      }
    }

    // Clean up dead handlers
    for id in deadIds {
      handlers.removeValue(forKey: id)
    }

    lock.unlock()

    // Invoke handlers outside the lock
    for h in aliveHandlers {
      h(e)
    }
  }
}

/// Convenience extensions for logging events to MsgLog.
public extension EventBus {
  /// Logs every event to MsgLog until the returned token is cancelled.
  @discardableResult
  func tapLog(level: MsgLog.Level = .debug, name: String? = nil, format: ((Event) -> String)? = nil) -> Token {
    onEach(owner: self) { event in
      let body = format?(event) ?? String(describing: event)
      if body.isEmpty { return }
      MsgLog.shared.write("[\(name ?? "EventBus")] \(body)", level: level)
    }
  }
}

/// A type-indexed global registry of shared ``EventBus`` instances.
///
/// Acts like a lazy singleton per event type within the current process. Useful when many
/// parts of an app need to rendezvous on a common bus without passing references around.
///
/// ### Example
/// ```swift
/// enum LogEvent { case line(String) }
/// let bus = ServiceLocator.resolve(LogEvent.self)
/// let token = bus.onEach { print($0) }
/// bus.publish(.line("ready"))
/// ```
public enum ServiceLocator {
  // safe because access is synchronized via `lock`
  private nonisolated(unsafe) static var map: [ObjectIdentifier: Any] = [:]
  private static let lock = NSLock()

  /// Returns the shared bus for the given event type.
  ///
  /// - Parameter _: The event type used to key the bus.
  /// - Returns: The process-wide shared ``EventBus`` for `E`.
  /// - Discussion: The bus is created on first access and reused thereafter.
  public static func resolve<E>(_: E.Type) -> EventBus<E> {
    let key = ObjectIdentifier(E.self)
    lock.lock()
    defer { lock.unlock() }
    if let any = map[key], let bus = any as? EventBus<E> { return bus }
    let bus = EventBus<E>()
    map[key] = bus
    return bus
  }

  /// Registers a value in the service locator.
  ///
  /// - Parameters:
  ///   - type: The type to key the value by.
  ///   - value: The value to register.
  public static func register<T>(_: T.Type, value: Any) {
    let key = ObjectIdentifier(T.self)
    lock.lock()
    defer { lock.unlock() }
    map[key] = value
  }

  /// Retrieves a previously registered value.
  ///
  /// - Parameter type: The type the value was registered with.
  /// - Returns: The registered value cast to the expected type, or nil if not found.
  public static func retrieve<T, V>(_: T.Type) -> V? {
    let key = ObjectIdentifier(T.self)
    lock.lock()
    defer { lock.unlock() }
    return map[key] as? V
  }
}

/// Protocol for events that can emit themselves to the service locator's event bus.
///
/// Conform your event enums to this protocol to enable self-emission via the `.emit()` method.
///
/// ### Example
/// ```swift
/// enum GameEvent: EmittableEvent {
///   case score(Int)
///   case playerDied
/// }
///
/// // Usage:
/// GameEvent.score(100).emit()
/// ```
public protocol EmittableEvent {
  /// Emits this event to the shared event bus.
  func emit()
}

public extension EmittableEvent {
  /// Emits this event to the service locator's event bus for this event type.
  func emit() {
    ServiceLocator.resolve(Self.self).publish(self)
  }
}
