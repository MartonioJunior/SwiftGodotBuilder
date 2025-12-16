import Foundation
import SwiftGodot

/// Sprite component for actors - handles animation and visual state
public struct ActorSprite: GView {
  public let state: ObservableState<ActorState>
  public var weaponState: ObservableState<ActorWeaponState>?

  private var actor: ActorState { state.wrappedValue }
  private var weapons: ActorWeaponState? { weaponState?.wrappedValue }

  public init(state: ObservableState<ActorState>, weaponState: ObservableState<ActorWeaponState>? = nil) {
    self.state = state
    self.weaponState = weaponState
  }

  public var body: some GView {
    AseSprite$(path: actor.spriteAsset)
      .centered(false)
      .position(actor.spriteOffset)
      .watch(state, \.facing) { sprite, facing in
        sprite.flipH = facing == .left
      }
      .watch(state, \.animationName) { sprite, anim in
        guard !anim.isEmpty,
              let frames = sprite.spriteFrames,
              frames.hasAnimation(anim: StringName(anim))
        else {
          GD.print("[ActorSprite] Animation '\(anim)' not found or empty")
          return
        }
        sprite.play(anim)
      }
      .onReady { sprite in
        actor.sprite = sprite

        if !actor.animationName.isEmpty,
           let frames = sprite.spriteFrames,
           frames.hasAnimation(anim: StringName(actor.animationName))
        {
          sprite.play(actor.animationName)
        }
      }
      .onProcess { sprite, _ in
        // Ensure animation is playing (handles case where frames weren't loaded at ready time)
        if !sprite.isPlaying(), !actor.animationName.isEmpty {
          sprite.play(actor.animationName)
        }

        // Squash/stretch
        sprite.scale = actor.scale
        sprite.rotation = Double(actor.rotation)

        // Compute modulate color
        sprite.modulate = computeModulate()
      }
  }

  private func computeModulate() -> Color {
    // Invincibility flash (highest priority)
    if actor.isInvincible {
      let flash = sin(actor.invincibilityTimer * 20) > 0
      return flash ? .white : Color(r: 0.5, g: 0.5, b: 1, a: 1)
    }

    // Dying fade
    if actor.isDying {
      return Color(r: 1, g: 1, b: 1, a: Float(max(0, 1 - actor.invincibilityTimer)))
    }

    // Attack phase colors
    if let weapons, weapons.phase.isAttacking {
      switch weapons.phase {
      case .startup:
        return Color.blue.lightened(amount: 0.2)
      case .active:
        return Color.yellow
      case .recovery:
        return Color.blue.darkened(amount: 0.1)
      case .idle:
        return .white
      }
    }

    return .white
  }
}
