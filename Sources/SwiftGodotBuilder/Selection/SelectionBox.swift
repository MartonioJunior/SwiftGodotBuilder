import Foundation
import SwiftGodot

/// A drag-to-select box UI component.
/// Handles click-to-select and box selection for selectable actors.
public struct SelectionBox: GView {
  /// Collision layer for selectable actors
  let selectableLayer: Physics2DLayer

  /// Visual style for the selection rectangle
  let boxColor: Color

  /// Minimum drag distance to trigger box selection vs click
  let minDragDistance: Float

  public init(
    selectableLayer: Physics2DLayer = .nu,
    boxColor: Color = Color(r: 0.2, g: 0.5, b: 1.0, a: 0.3),
    minDragDistance: Float = 5
  ) {
    self.selectableLayer = selectableLayer
    self.boxColor = boxColor
    self.minDragDistance = minDragDistance
  }

  public var body: some GView {
    SelectionBoxImpl(
      selectableLayer: selectableLayer,
      boxColor: boxColor,
      minDragDistance: minDragDistance
    )
  }
}

// MARK: - Implementation

private struct SelectionBoxImpl: GView {
  let selectableLayer: Physics2DLayer
  let boxColor: Color
  let minDragDistance: Float

  @State var isDragging = false
  @State var dragStart: Vector2 = .zero
  @State var dragCurrent: Vector2 = .zero
  @State var wasMousePressed = false

  var body: some GView {
    CanvasLayer$ {
      // Selection rectangle visual (drawn when dragging)
      SelectionRectView(
        isDragging: $isDragging,
        dragStart: $dragStart,
        dragCurrent: $dragCurrent,
        boxColor: boxColor,
        minDragDistance: minDragDistance
      )
    }
    .onProcess { node, _ in
      guard let viewport = node.getViewport() else { return }

      let mousePos = viewport.getMousePosition()
      let isMousePressed = Input.isMouseButtonPressed(button: .left)
      let isShiftHeld = Input.isKeyPressed(keycode: .shift)

      // Mouse just pressed
      if isMousePressed && !wasMousePressed {
        dragStart = mousePos
        dragCurrent = mousePos
        isDragging = true
      }

      // Mouse being held - update drag position
      if isMousePressed && isDragging {
        dragCurrent = mousePos
      }

      // Mouse just released
      if !isMousePressed && wasMousePressed && isDragging {
        let dragDistance = dragStart.distanceTo(dragCurrent)

        if dragDistance < Double(minDragDistance) {
          // Click selection
          handleClickSelection(at: dragCurrent, additive: isShiftHeld, viewport: viewport)
        } else {
          // Box selection
          handleBoxSelection(from: dragStart, to: dragCurrent, additive: isShiftHeld, viewport: viewport)
        }

        isDragging = false
      }

      wasMousePressed = isMousePressed
    }
  }

  private func handleClickSelection(at position: Vector2, additive: Bool, viewport: Viewport) {
    // Convert screen position to world position
    let worldPos = screenToWorld(position, viewport: viewport)
    GD.print("SelectionBox: click at screen \(position), world \(worldPos)")

    // Query for selectable actors at this point
    guard let spaceState = viewport.findWorld2d()?.directSpaceState else {
      GD.print("SelectionBox: no space state")
      if !additive { SelectionEvent.clearRequested.emit() }
      return
    }

    let query = PhysicsPointQueryParameters2D()
    query.position = worldPos
    query.collisionMask = UInt32(selectableLayer.rawValue)
    query.collideWithAreas = true
    GD.print("SelectionBox: querying layer mask \(selectableLayer.rawValue)")

    let results = spaceState.intersectPoint(parameters: query)
    GD.print("SelectionBox: found \(results.count) results")

    if results.isEmpty {
      // Clicked on nothing
      if !additive {
        SelectionEvent.clearRequested.emit()
      }
      return
    }

    // Find selectbox Area2D instance IDs from the results
    var areaIds = Set<Int>()
    for result in results {
      if let colliderVariant = result["collider"] {
        if let area = colliderVariant.asObject() as? Area2D {
          let areaId = Int(area.getInstanceId())
          areaIds.insert(areaId)
          GD.print("SelectionBox: found area \(areaId)")
        }
      }
    }

    if areaIds.isEmpty {
      GD.print("SelectionBox: no areas found in results")
      if !additive {
        SelectionEvent.clearRequested.emit()
      }
      return
    }

    // For click selection, just use the first area found
    if let firstId = areaIds.first {
      GD.print("SelectionBox: emitting select for area \(firstId)")
      if additive {
        SelectionEvent.toggleRequested(actorId: firstId).emit()
      } else {
        SelectionEvent.selectRequested(actorIds: areaIds, additive: false).emit()
      }
    }
  }

  private func handleBoxSelection(from: Vector2, to: Vector2, additive: Bool, viewport: Viewport) {
    guard let spaceState = viewport.findWorld2d()?.directSpaceState else { return }

    // Convert screen rect to world rect
    let worldFrom = screenToWorld(from, viewport: viewport)
    let worldTo = screenToWorld(to, viewport: viewport)
    GD.print("SelectionBox: box from \(worldFrom) to \(worldTo)")

    let minX = min(worldFrom.x, worldTo.x)
    let minY = min(worldFrom.y, worldTo.y)
    let maxX = max(worldFrom.x, worldTo.x)
    let maxY = max(worldFrom.y, worldTo.y)

    let width = maxX - minX
    let height = maxY - minY

    // Create a rectangle shape for the query
    let shape = RectangleShape2D()
    shape.size = [Float(width), Float(height)]

    let query = PhysicsShapeQueryParameters2D()
    query.shape = shape
    query.transform = Transform2D(rotation: 0, position: [Float((minX + maxX) / 2), Float((minY + maxY) / 2)])
    query.collisionMask = UInt32(selectableLayer.rawValue)
    query.collideWithAreas = true

    let results = spaceState.intersectShape(parameters: query)
    GD.print("SelectionBox: box query found \(results.count) results")

    var areaIds = Set<Int>()
    for result in results {
      if let colliderVariant = result["collider"] {
        if let area = colliderVariant.asObject() as? Area2D {
          let areaId = Int(area.getInstanceId())
          areaIds.insert(areaId)
          GD.print("SelectionBox: found area \(areaId)")
        }
      }
    }

    GD.print("SelectionBox: emitting select for \(areaIds.count) areas")
    SelectionEvent.selectRequested(actorIds: areaIds, additive: additive).emit()
  }

  private func screenToWorld(_ screenPos: Vector2, viewport: Viewport) -> Vector2 {
    // Get the canvas transform which includes camera position and zoom
    let canvasTransform = viewport.canvasTransform
    return canvasTransform.affineInverse() * screenPos
  }
}

// MARK: - Selection Rectangle Visual

private struct SelectionRectView: GView {
  let isDragging: State<Bool>
  let dragStart: State<Vector2>
  let dragCurrent: State<Vector2>
  let boxColor: Color
  let minDragDistance: Float

  var body: some GView {
    ColorRect$()
      .color(boxColor)
      .onProcess { node, _ in
        guard let rect = node as? ColorRect else { return }

        let dragging = isDragging.wrappedValue
        let start = dragStart.wrappedValue
        let current = dragCurrent.wrappedValue
        let distance = start.distanceTo(current)

        let shouldShow = dragging && distance >= Double(minDragDistance)
        rect.visible = shouldShow

        if shouldShow {
          let minX = Double(min(start.x, current.x))
          let minY = Double(min(start.y, current.y))
          let width = Double(abs(current.x - start.x))
          let height = Double(abs(current.y - start.y))

          // Use offset properties for Control positioning
          rect.offsetLeft = minX
          rect.offsetTop = minY
          rect.offsetRight = minX + width
          rect.offsetBottom = minY + height
        }
      }
  }
}
