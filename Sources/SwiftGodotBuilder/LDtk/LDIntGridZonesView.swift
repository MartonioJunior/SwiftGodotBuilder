import SwiftGodot

/// A declarative view that builds Area2D collision zones from an LDtk IntGrid layer.
///
/// Each IntGrid value with an identifier becomes a collision zone. Use handlers to
/// respond to bodies entering/exiting zones.
///
/// ### Basic Usage:
/// ```swift
/// LDIntGridZonesView(layer: hazardLayer, project: project)
///   .collisionLayer(.hazard)
///   .collisionMask(.player)
///   .onZoneEnter { zone, body in
///     if zone.identifier == "damage" {
///       GameEvent.playerHit(damage: 1).emit()
///     }
///   }
/// ```
///
/// ### IntGrid Setup in LDtk:
/// Add identifiers to IntGrid values (e.g., "Damage", "Kill", "Water").
/// The identifier becomes `zone.identifier` in your handlers.
public struct LDIntGridZonesView: GView {
  let layer: LDLayer
  let project: LDProject

  private var zoneCollisionLayer: UInt32 = 0
  private var zoneCollisionMask: UInt32 = 1
  private var onEnterHandler: ((LDIntGridZone, Node) -> Void)?
  private var onExitHandler: ((LDIntGridZone, Node) -> Void)?

  /// Initialize with an IntGrid layer.
  /// - Parameters:
  ///   - layer: The IntGrid layer to build zones from
  ///   - project: The LDtk project (for layer definitions)
  public init(layer: LDLayer, project: LDProject) {
    self.layer = layer
    self.project = project
  }

  public var body: some GView {
    Node2D$ {
      for zone in zones {
        ZoneAreaNode(
          zone: zone,
          collisionLayer: zoneCollisionLayer,
          collisionMask: zoneCollisionMask,
          onEnter: onEnterHandler,
          onExit: onExitHandler
        )
      }
    }
    .position(layer.totalOffset)
  }

  // MARK: - Configuration

  /// Set the collision layer for all zones.
  public func collisionLayer(_ layer: UInt32) -> Self {
    var view = self
    view.zoneCollisionLayer = layer
    return view
  }

  /// Set the collision mask for all zones.
  public func collisionMask(_ mask: UInt32) -> Self {
    var view = self
    view.zoneCollisionMask = mask
    return view
  }

  /// Handle when a body enters a zone.
  /// - Parameter handler: Closure called with the zone data and entering body
  public func onZoneEnter(_ handler: @escaping (LDIntGridZone, Node) -> Void) -> Self {
    var view = self
    view.onEnterHandler = handler
    return view
  }

  /// Handle when a body exits a zone.
  /// - Parameter handler: Closure called with the zone data and exiting body
  public func onZoneExit(_ handler: @escaping (LDIntGridZone, Node) -> Void) -> Self {
    var view = self
    view.onExitHandler = handler
    return view
  }

  // MARK: - Zone Building

  private var zones: [LDIntGridZone] {
    guard let layerDef = project.defs.layer(uid: layer.layerDefUid) else {
      return []
    }

    // Build value -> identifier mapping
    var valueToIdentifier: [Int: String] = [:]
    for intGridValue in layerDef.intGridValues {
      if let identifier = intGridValue.identifier {
        valueToIdentifier[intGridValue.value] = identifier
      }
    }

    // Scan grid and build zones
    var result: [LDIntGridZone] = []
    let gridSize = layer.gridSize

    for y in 0 ..< layer.cHei {
      for x in 0 ..< layer.cWid {
        if let value = layer.intGridValue(x: x, y: y),
           let identifier = valueToIdentifier[value]
        {
          let position = Vector2(x: Float(x * gridSize), y: Float(y * gridSize))
          let size = Vector2(x: Float(gridSize), y: Float(gridSize))
          result.append(LDIntGridZone(
            identifier: identifier.lowercased(),
            value: value,
            position: position,
            size: size,
            gridX: x,
            gridY: y
          ))
        }
      }
    }

    return result
  }
}

// MARK: - Zone Data

/// Data for an IntGrid zone cell.
public struct LDIntGridZone {
  /// The identifier from the IntGrid value (lowercased).
  public let identifier: String

  /// The raw IntGrid value.
  public let value: Int

  /// Position in pixels relative to the layer.
  public let position: Vector2

  /// Size in pixels (typically gridSize x gridSize).
  public let size: Vector2

  /// Grid X coordinate.
  public let gridX: Int

  /// Grid Y coordinate.
  public let gridY: Int

  /// Center position of the zone.
  public var center: Vector2 {
    position + size / 2
  }
}

// MARK: - Zone Metadata

private let zoneIdentifierMeta = "zone_identifier"
private let zoneValueMeta = "zone_value"

extension Area2D {
  /// Get the zone identifier if this Area2D is an IntGrid zone.
  public var zoneIdentifier: String? {
    guard let v = getMeta(name: StringName(zoneIdentifierMeta), default: nil) else { return nil }
    return String(v)
  }

  /// Get the zone value if this Area2D is an IntGrid zone.
  public var zoneValue: Int? {
    guard let v = getMeta(name: StringName(zoneValueMeta), default: nil) else { return nil }
    return v.gtype == .int ? Int(v) : nil
  }
}

// MARK: - Internal Zone Node

private struct ZoneAreaNode: GView {
  let zone: LDIntGridZone
  let collisionLayer: UInt32
  let collisionMask: UInt32
  let onEnter: ((LDIntGridZone, Node) -> Void)?
  let onExit: ((LDIntGridZone, Node) -> Void)?

  var body: some GView {
    Area2D$ {
      CollisionShape2D$()
        .shape(RectangleShape2D(size: zone.size))
        .position(zone.size / 2)
    }
    .position(zone.position)
    .collisionLayer(collisionLayer)
    .collisionMask(collisionMask)
    .onReady { node in
      node.setMeta(name: StringName(zoneIdentifierMeta), value: Variant(zone.identifier))
      node.setMeta(name: StringName(zoneValueMeta), value: Variant(zone.value))
    }
    .onSignal(\.bodyEntered) { _, body in
      guard let body else { return }
      onEnter?(zone, body)
    }
    .onSignal(\.bodyExited) { _, body in
      guard let body else { return }
      onExit?(zone, body)
    }
  }
}
