import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// NPC as an Actor - interactable entities that can trigger dialog
  struct NPCActorView: GView {
    let entity: LDEntity
    let npcType: NPCType
    let definition: NPCDefinition
    let worldGravity: Float

    private final class ViewModel {
      var actorId: Int = 0
    }

    private let vm = ViewModel()

    init(entity: LDEntity, worldGravity: Float) {
      self.entity = entity
      self.worldGravity = worldGravity
      npcType = entity.field("npcType")?.asEnum() ?? .oldMan
      definition = npcType.definition
    }

    var body: some GView {
      Node2D$ {
        ActorView(
          entity: entity,
          spriteAsset: "Mobs",
          animations: definition.animations,
          collisionLayers: Chapter27.actorCollisionLayers,
          controller: StationaryController(),
          physics: .npc,
          combat: ActorCombat(maxHealth: 999, canDealTouchDamage: false, canReceiveDamage: false),
          capabilities: .npc,
          worldGravity: worldGravity,
          npcTypeId: npcType.rawValue,
          displayName: definition.name
        )
        .onActorReady { [vm] actor in
          vm.actorId = actor.id
        }
      }
      .onEvent(ActorEvent.self) { [vm, npcType] _, event in
        if case let .interacted(id, _) = event, id == vm.actorId {
          GD.print("[NPCActorView] Interacted with \(npcType)")
          DialogEvent.npcInteracted(npcType: npcType).emit()
        }
      }
    }
  }
}
