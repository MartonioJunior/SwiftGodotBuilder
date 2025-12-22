import Foundation
import SwiftGodot

// MARK: - Scene Router Protocol

/// Protocol for scene routers.
public protocol SceneRouterProtocol: AnyObject {
  associatedtype Scene: Hashable

  /// The current scene
  var scene: Scene { get set }

  /// Reactive binding to the current scene for use with Switch
  var sceneBinding: GState<Scene> { get }

  /// The transition state for visual effects
  var transitionState: TransitionState { get }

  /// Navigate to a new scene with an optional transition effect.
  func navigate(to scene: Scene, transition: TransitionStyle, onComplete: (() -> Void)?)

  /// Navigate to a new scene with a transition, executing additional work at the midpoint.
  func navigate(to scene: Scene, transition: TransitionStyle, atMidpoint: @escaping () -> Void, onComplete: (() -> Void)?)
}

// MARK: - Scene Router

/// A router for managing scene navigation with built-in transition support.
///
/// SceneRouter provides a Vue Router-inspired API for navigating between scenes
/// with automatic transition handling:
///
/// ```swift
/// let router = SceneRouter(initial: GameState.splash)
///
/// // Navigate with transitions
/// router.navigate(to: .levelSelect, transition: .wipe())
/// router.navigate(to: .death, transition: .iris(center: playerPos))
///
/// // Nested routes (like Vue Router children)
/// let levelRouter = router.child(for: .playing, initial: 1)
/// levelRouter.scene = .level3  // Switch to level 3
/// ```
///
/// Use with Switch for reactive UI:
/// ```swift
/// Switch(router.sceneBinding) {
///   Case(.splash) { SplashOverlay(router: router) }
///   Case(.welcome) { WelcomeOverlay(router: router) }
///   Case(.playing) { GameLevel(router: router) }
/// }
/// .mode(.destroy)  // Memory management
/// ```
public class SceneRouter<Scene: Hashable & Equatable>: SceneRouterProtocol {
  /// Internal GState for the current scene
  private let _scene: GState<Scene>

  /// The current scene
  public var scene: Scene {
    get { _scene.wrappedValue }
    set { _scene.wrappedValue = newValue }
  }

  /// Reactive binding to the current scene for use with Switch
  public var sceneBinding: GState<Scene> { _scene }

  /// The transition state for visual effects
  public let transitionState = TransitionState()

  /// Child routers for nested routes
  private var childRouters: [AnyHashable: Any] = [:]

  /// Creates a new router with an initial scene
  public init(initial: Scene) {
    _scene = GState(wrappedValue: initial)
  }

  /// Navigate to a new scene with an optional transition effect.
  ///
  /// The scene change happens at the transition's midpoint (when the screen is fully covered),
  /// ensuring a smooth visual transition.
  ///
  /// - Parameters:
  ///   - scene: The destination scene
  ///   - transition: The transition style to use (default: `.fade()`)
  ///   - onComplete: Optional callback when the transition completes
  public func navigate(
    to scene: Scene,
    transition: TransitionStyle = .fade(),
    onComplete: (() -> Void)? = nil
  ) {
    switch transition {
    case .none:
      self.scene = scene
      onComplete?()

    case let .fade(duration):
      transitionState.fadeTransition(
        duration: duration,
        onMidpoint: { self.scene = scene },
        onComplete: onComplete
      )

    case let .wipe(duration):
      transitionState.wipeTransition(
        duration: duration,
        onMidpoint: { self.scene = scene },
        onComplete: onComplete
      )

    case let .iris(duration, center):
      transitionState.irisOutTransition(
        duration: duration,
        center: center,
        onMidpoint: { self.scene = scene },
        onComplete: onComplete
      )
    }
  }

  /// Navigate to a new scene with a transition, executing additional work at the midpoint.
  ///
  /// Use this when you need to perform setup when the scene changes (e.g., resetting game state):
  /// ```swift
  /// router.navigate(to: .playing, transition: .fade()) {
  ///   state.reset()
  ///   state.currentLevelId = levelId
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - scene: The destination scene
  ///   - transition: The transition style to use
  ///   - atMidpoint: Additional work to perform at midpoint (after scene change)
  ///   - onComplete: Optional callback when the transition completes
  public func navigate(
    to scene: Scene,
    transition: TransitionStyle,
    atMidpoint: @escaping () -> Void,
    onComplete: (() -> Void)? = nil
  ) {
    switch transition {
    case .none:
      self.scene = scene
      atMidpoint()
      onComplete?()

    case let .fade(duration):
      transitionState.fadeTransition(
        duration: duration,
        onMidpoint: { self.scene = scene; atMidpoint() },
        onComplete: onComplete
      )

    case let .wipe(duration):
      transitionState.wipeTransition(
        duration: duration,
        onMidpoint: { self.scene = scene; atMidpoint() },
        onComplete: onComplete
      )

    case let .iris(duration, center):
      transitionState.irisOutTransition(
        duration: duration,
        center: center,
        onMidpoint: { self.scene = scene; atMidpoint() },
        onComplete: onComplete
      )
    }
  }

  /// Get or create a child router for nested routes.
  ///
  /// Child routers are lazily created and cached. This enables Vue Router-style
  /// nested routing where a parent scene can have its own sub-navigation:
  ///
  /// ```swift
  /// // Main router for game states
  /// let router = SceneRouter(initial: GameState.splash)
  ///
  /// // Nested router for levels within the .playing state
  /// let levelRouter = router.child(for: .playing, initial: 1)
  ///
  /// // Navigate to level 3
  /// levelRouter.navigate(to: 3, transition: .fade())
  /// ```
  ///
  /// - Parameters:
  ///   - parent: The parent scene that owns this child router
  ///   - initial: The initial scene for the child router
  /// - Returns: The child router (created if needed)
  public func child<ChildScene: Hashable & Equatable>(
    for parent: Scene,
    initial: ChildScene
  ) -> SceneRouter<ChildScene> {
    let key = AnyHashable(parent)
    if let existing = childRouters[key] as? SceneRouter<ChildScene> {
      return existing
    }
    let child = SceneRouter<ChildScene>(initial: initial)
    childRouters[key] = child
    return child
  }
}
