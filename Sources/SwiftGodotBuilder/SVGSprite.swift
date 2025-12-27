import Foundation
import SwiftGodot

/// A Godot `Node2D` subclass that loads SVG files and converts them to
/// native Godot vector graphics (Polygon2D, Line2D).
///
/// This class parses SVG paths and basic shapes, converting them to Godot
/// primitives for resolution-independent rendering with runtime modification support.
///
/// ### Features
/// - Parses SVG paths, circles, rectangles, ellipses
/// - Converts to Polygon2D for filled shapes
/// - Converts to Line2D for stroked paths
/// - Supports runtime colorization
/// - Allows vertex manipulation
/// - Resolution-independent scaling
///
/// ### Limitations
/// - No gradient support
/// - No text elements
/// - No filters or effects
///
/// ### Example
/// ```swift
/// let icon = SVGSprite("icon.svg") // defaults to 32px
///
/// // Runtime colorization
/// icon.setColor(.red, forElement: 0)
///
/// // Vertex manipulation
/// if let vertices = icon.getVertices(0) {
///   var modified = vertices
///   // Modify vertices...
///   icon.setVertices(modified, forElement: 0)
/// }
/// ```
@Godot
public class SVGSprite: Node2D {
  // MARK: Configuration

  /// Path to the SVG file
  public var path: String = ""

  /// Target size in pixels for the largest dimension (width or height).
  /// Automatically scales the SVG so its largest dimension equals this size.
  public var size: Float = 32

  /// Quality of curve tessellation (higher = smoother curves, more vertices)
  public var tessellation: Float = 1.0

  /// Override all colors in the SVG with this color (nil = use SVG colors)
  public var color: Color?

  /// Per-element colors (overrides `color` for specific elements).
  /// When set, each subpath renders separately. When empty, inner paths cut out as holes.
  public var colors: [Color] = []

  /// Stroke color for outlines (nil = no stroke, or use SVG stroke)
  public var strokeColor: Color?

  /// Stroke width in pixels (scaled with SVG)
  public var strokeWidth: Float = 1.0

  /// Per-element stroke colors (overrides `strokeColor` for specific elements)
  public var strokeColors: [Color] = []

  /// Flip the Y axis (SVG uses top-down, Godot can use bottom-up for certain setups)
  public var flipY = false

  // MARK: Internal state

  /// Internal calculated scale (set during parsing based on size and viewBox)
  var calculatedScale: Float = 1.0

  /// Counter incremented each time the sprite rebuilds. Used by effects to detect stale state.
  public private(set) var rebuildCount: Int = 0

  private var elements: [SVGElement] = []
  private var strokeElements: [Line2D] = []
  private var lastConfig: (path: String, size: Float, tessellation: Float, strokeColor: Color?, strokeWidth: Float)?

  // MARK: Lifecycle

  /// Initializes with an SVG file path.
  ///
  /// - Parameter path: Path to the SVG file
  public convenience init(_ path: String) {
    self.init()
    self.path = path
  }

  override public func _ready() {
    if !path.isEmpty {
      buildFromSVG()
      applyColors()
      applyStrokeColors()
    }
  }

  override public func _process(delta _: Double) {
    // Rebuild if config changed, then re-apply colors
    if !path.isEmpty && buildFromSVG() {
      applyColors()
      applyStrokeColors()
    }
  }

  /// Applies per-element colors from the `colors` array.
  /// The first color in the array acts as the base color for all elements,
  /// then subsequent colors override specific elements.
  private func applyColors() {
    // If colors array has items, use first color as base for all elements
    if let baseColor = colors.first {
      for i in 0 ..< elements.count {
        setColor(baseColor, forElement: i)
      }
    }
    // Then apply any additional colors to specific elements
    for (index, color) in colors.enumerated() {
      setColor(color, forElement: index)
    }
  }

  /// Applies per-element stroke colors from the `strokeColors` array.
  private func applyStrokeColors() {
    for (index, color) in strokeColors.enumerated() {
      setStrokeColor(color, forElement: index)
    }
  }

  // MARK: Runtime Modification API

  /// Sets the color for a specific element.
  ///
  /// - Parameters:
  ///   - color: The new color
  ///   - index: The element index
  public func setColor(_ color: Color, forElement index: Int) {
    guard index < elements.count else { return }

    let element = elements[index]

    if let polygon = element.node as? Polygon2D {
      polygon.color = color
    } else if let line = element.node as? Line2D {
      line.defaultColor = color
    }
  }

  /// Sets the stroke color for a specific element.
  ///
  /// - Parameters:
  ///   - color: The new stroke color
  ///   - index: The element index
  public func setStrokeColor(_ color: Color, forElement index: Int) {
    guard index < strokeElements.count else { return }
    strokeElements[index].defaultColor = color
  }

  /// Gets the vertices for a specific element.
  ///
  /// - Parameter index: The element index
  /// - Returns: The vertex array, or nil if not a polygon
  public func getVertices(_ index: Int) -> PackedVector2Array? {
    guard index < elements.count else { return nil }
    let element = elements[index]

    if let polygon = element.node as? Polygon2D {
      return polygon.polygon
    } else if let line = element.node as? Line2D {
      return line.points
    }

    return nil
  }

  /// Sets the vertices for a specific element.
  /// Also updates the corresponding stroke element if one exists.
  ///
  /// - Parameters:
  ///   - vertices: The new vertex array
  ///   - index: The element index
  public func setVertices(_ vertices: PackedVector2Array, forElement index: Int) {
    guard index < elements.count else { return }
    let element = elements[index]

    if let polygon = element.node as? Polygon2D {
      polygon.polygon = vertices
    } else if let line = element.node as? Line2D {
      line.points = vertices
    }

    // Also update corresponding stroke if it exists
    if index < strokeElements.count {
      let stroke = strokeElements[index]
      // Strokes need to be closed - add first point at end if not already closed
      let strokePoints = vertices
      if strokePoints.size() > 0 && strokePoints[0] != strokePoints[Int(strokePoints.size()) - 1] {
        strokePoints.append(strokePoints[0])
      }
      stroke.points = strokePoints
    }
  }

  /// Gets the total number of elements in this SVG.
  public func getElementCount() -> Int {
    return elements.count
  }

  // MARK: Build

  /// Parses the SVG and builds the Godot node hierarchy.
  /// Returns true if the SVG was rebuilt.
  @discardableResult
  func buildFromSVG() -> Bool {
    let cfg = (path, size, tessellation, strokeColor, strokeWidth)

    // Check if already built with same config
    if let last = lastConfig,
       last.path == cfg.0 &&
       last.size == cfg.1 &&
       last.tessellation == cfg.2 &&
       last.strokeColor == cfg.3 &&
       last.strokeWidth == cfg.4
    {
      return false
    }

    lastConfig = cfg
    rebuildCount += 1

    // Clear existing elements
    for element in elements {
      element.node.queueFree()
    }
    elements.removeAll()

    // Clear existing stroke elements
    for stroke in strokeElements {
      stroke.queueFree()
    }
    strokeElements.removeAll()

    // Parse SVG
    guard let parsed = parseSVG(path) else {
      GD.printErr("⚠️ SVGSprite failed to parse", path)
      return false
    }

    // Build Godot nodes from parsed data
    for shape in parsed.shapes {
      // Build fill element first
      if let element = buildElement(from: shape) {
        addChild(node: element.node)
        elements.append(element)
      }

      // Create stroke on top with z_index to ensure visibility
      // strokeWidth is in final pixels, NOT scaled
      if let strokeColor = strokeColor {
        if let strokeLine = buildStroke(from: shape, color: strokeColor, width: strokeWidth) {
          strokeLine.zIndex = 1
          addChild(node: strokeLine)
          strokeElements.append(strokeLine)
        }
      }
    }
    return true
  }

  /// Builds a stroke Line2D from a shape.
  private func buildStroke(from shape: SVGShape, color: Color, width: Float) -> Line2D? {
    switch shape {
    case let .polygon(vertices, _, _):
      guard !vertices.isEmpty else { return nil }
      let line = Line2D()
      var points = vertices
      // Close the path for strokes
      if points.first != points.last {
        points.append(points[0])
      }
      line.points = PackedVector2Array(points)
      line.defaultColor = color
      line.width = Double(width)
      line.jointMode = .round
      line.beginCapMode = .round
      line.endCapMode = .round
      line.antialiased = true
      return line

    case let .polygonWithHoles(vertices, polygons, _, _):
      // For polygons with holes, stroke each subpath
      // Return the first (outer) path as the main stroke
      guard !polygons.isEmpty else { return nil }
      let indices = polygons[0]
      var points: [Vector2] = []
      for i in 0 ..< Int(indices.size()) {
        let idx = Int(indices[i])
        if idx < vertices.count {
          points.append(vertices[idx])
        }
      }
      guard !points.isEmpty else { return nil }
      // Close the path
      if points.first != points.last {
        points.append(points[0])
      }
      let line = Line2D()
      line.antialiased = true
      line.points = PackedVector2Array(points)
      line.defaultColor = color
      line.width = Double(width)
      line.jointMode = .round
      line.beginCapMode = .round
      line.endCapMode = .round
      return line
    }
  }

  /// Builds a Godot node from a parsed SVG shape.
  private func buildElement(from shape: SVGShape) -> SVGElement? {
    switch shape {
    case let .polygon(vertices, fill, stroke):
      if let fill = fill {
        let polygon = Polygon2D()
        polygon.polygon = PackedVector2Array(vertices)
        polygon.color = fill
        polygon.antialiased = true
        return SVGElement(node: polygon, type: .fill)
      } else if let stroke = stroke {
        let line = Line2D()
        line.antialiased = true
        line.points = PackedVector2Array(vertices)
        line.defaultColor = stroke.color
        line.width = Double(stroke.width)
        return SVGElement(node: line, type: .stroke)
      }
      return nil

    case let .polygonWithHoles(vertices, polygons, fill, stroke):
      if let fill = fill {
        let polygon = Polygon2D()
        polygon.polygon = PackedVector2Array(vertices)
        polygon.color = fill
        polygon.antialiased = true
        // Set up polygon indices for hole support
        let polygonsArray = VariantArray()
        for p in polygons {
          polygonsArray.append(Variant(p))
        }
        polygon.polygons = polygonsArray
        return SVGElement(node: polygon, type: .fill)
      } else if let stroke = stroke {
        // For stroke-only, draw each subpath as a line
        let container = Node2D()
        var offset = 0
        for indices in polygons {
          let line = Line2D()
          var points: [Vector2] = []
          for i in 0 ..< Int(indices.size()) {
            let idx = Int(indices[i])
            if idx < vertices.count {
              points.append(vertices[idx])
            }
          }
          line.antialiased = true
          line.points = PackedVector2Array(points)
          line.defaultColor = stroke.color
          line.width = Double(stroke.width)
          line.closed = true
          container.addChild(node: line)
          offset += Int(indices.size())
        }
        return SVGElement(node: container, type: .stroke)
      }
      return nil
    }
  }

  /// Parses an SVG file and returns structured data.
  private func parseSVG(_ path: String) -> ParsedSVG? {
    // Load SVG file
    let fullPath = path.hasSuffix(".svg") ? path : path + ".svg"
    let svgString = FileAccess.getFileAsString(path: fullPath)

    guard !svgString.isEmpty else {
      GD.printErr("⚠️ Failed to load SVG file:", fullPath)
      return nil
    }

    // Parse SVG using SwiftDrawDOM
    let domSVG: DOM.SVG
    do {
      domSVG = try DOM.SVG.parse(xml: svgString)
    } catch {
      GD.printErr("⚠️ Failed to parse SVG XML:", fullPath, error)
      return nil
    }

    // Extract viewBox
    let viewBox: (x: Float, y: Float, width: Float, height: Float)?
    if let vb = domSVG.viewBox {
      viewBox = (x: vb.x, y: vb.y, width: vb.width, height: vb.height)
    } else {
      viewBox = nil
    }

    // Calculate scale based on size and viewBox
    if let vb = viewBox {
      calculatedScale = size / max(vb.width, vb.height)
    } else {
      // No viewBox, use size as direct scale
      calculatedScale = size
    }

    // Build options
    // Use holes for cutout effect when no per-element colors are set
    let options = SVGOptions(
      size: size,
      tessellation: tessellation,
      color: color,
      flipY: flipY,
      useHoles: colors.isEmpty,
      calculatedScale: calculatedScale
    )

    // Extract shapes from DOM
    let shapes = extractShapes(from: domSVG.childElements, options: options)

    return ParsedSVG(shapes: shapes, viewBox: viewBox)
  }

  /// Recursively extracts shapes from DOM elements.
  private func extractShapes(from elements: [DOM.GraphicsElement], options: SVGOptions) -> [SVGShape] {
    var shapes: [SVGShape] = []

    for element in elements {
      // Get fill and stroke from presentation attributes
      let fill = getColor(from: element.attributes.fill, options: options)
      let stroke = getStroke(from: element, options: options)

      switch element {
      case let path as DOM.Path:
        shapes.append(contentsOf: extractPathShapes(path, fill: fill, stroke: stroke, options: options))

      case let rect as DOM.Rect:
        shapes.append(extractRectShape(rect, fill: fill, stroke: stroke, options: options))

      case let circle as DOM.Circle:
        shapes.append(extractCircleShape(circle, fill: fill, stroke: stroke, options: options))

      case let ellipse as DOM.Ellipse:
        shapes.append(extractEllipseShape(ellipse, fill: fill, stroke: stroke, options: options))

      case let line as DOM.Line:
        shapes.append(extractLineShape(line, stroke: stroke, options: options))

      case let polygon as DOM.Polygon:
        shapes.append(extractPolygonShape(polygon, fill: fill, stroke: stroke, options: options, closed: true))

      case let polyline as DOM.Polyline:
        shapes.append(extractPolygonShape(polyline, fill: fill, stroke: stroke, options: options, closed: false))

      case let group as DOM.Group:
        // Recursively process group children
        shapes.append(contentsOf: extractShapes(from: group.childElements, options: options))

      default:
        // Ignore unsupported element types
        break
      }
    }

    return shapes
  }
}

// MARK: - Supporting Types

/// Represents a parsed SVG element in the Godot scene.
private struct SVGElement {
  let node: Node2D
  let type: ElementType

  enum ElementType {
    case fill
    case stroke
  }
}

/// Internal options structure used during SVG parsing.
struct SVGOptions {
  /// Target size in pixels for the largest dimension (width or height).
  /// Automatically scales the SVG so its largest dimension equals this size,
  /// ensuring consistent sizing across different SVGs. Defaults to 32px.
  public var size: Float

  /// Quality of curve tessellation (higher = smoother curves, more vertices)
  public var tessellation: Float = 1.0

  /// Override all colors in the SVG with this color (nil = use SVG colors)
  public var color: Color?

  /// Flip the Y axis (SVG uses top-down, Godot uses bottom-up)
  public var flipY: Bool = false

  /// When true, inner paths are cut out as holes. When false, each path renders separately.
  var useHoles: Bool = true

  /// Internal calculated scale (set during parsing based on size and viewBox)
  var calculatedScale: Float = 1.0

  public init(size: Float = 32,
              tessellation: Float = 1.0,
              color: Color? = nil,
              flipY: Bool = false,
              useHoles: Bool = true,
              calculatedScale: Float = 1.0)
  {
    self.size = size
    self.tessellation = tessellation
    self.color = color
    self.flipY = flipY
    self.useHoles = useHoles
    self.calculatedScale = calculatedScale
  }
}

// MARK: - SVG Parsing

/// Parsed SVG data ready for conversion to Godot nodes.
private struct ParsedSVG {
  let shapes: [SVGShape]
  let viewBox: (x: Float, y: Float, width: Float, height: Float)?
}

/// A shape extracted from an SVG.
private enum SVGShape {
  case polygon(vertices: [Vector2], fill: Color?, stroke: StrokeStyle?)
  case polygonWithHoles(vertices: [Vector2], polygons: [PackedInt32Array], fill: Color?, stroke: StrokeStyle?)
}

/// Stroke styling information.
private struct StrokeStyle {
  let color: Color
  let width: Float
}

// MARK: - Shape Extraction Helpers

extension SVGSprite {
  /// Extracts color from DOM.Fill, applying color override if set.
  private func getColor(from fill: DOM.Fill?, options: SVGOptions) -> Color? {
    // Apply color override if set
    if let override = options.color {
      return override
    }

    guard let fill = fill else { return nil }

    switch fill {
    case let .color(domColor):
      return convertColor(domColor)
    case .url:
      // Gradients not supported, ignore
      return nil
    }
  }

  /// Extracts stroke from DOM element attributes.
  private func getStroke(from element: DOM.GraphicsElement, options: SVGOptions) -> StrokeStyle? {
    guard let stroke = element.attributes.stroke else { return nil }

    let color: Color
    switch stroke {
    case let .color(domColor):
      color = convertColor(domColor)
    case .url:
      // Gradients not supported, ignore
      return nil
    }

    // Apply color override if set
    let finalColor = options.color ?? color

    // Get stroke width (default to 1.0)
    let width = element.attributes.strokeWidth ?? 1.0

    return StrokeStyle(color: finalColor, width: width * options.calculatedScale)
  }

  /// Converts DOM.Color to Godot Color.
  private func convertColor(_ domColor: DOM.Color) -> Color {
    return Color(
      r: domColor.r,
      g: domColor.g,
      b: domColor.b,
      a: domColor.a
    )
  }

  /// Transforms a DOM.Point to Godot Vector2 with scaling and flip.
  private func transform(_ point: DOM.Point, options: SVGOptions) -> Vector2 {
    var p = Vector2(x: point.x, y: point.y)
    p.x *= options.calculatedScale
    p.y *= options.calculatedScale

    if options.flipY {
      p.y = -p.y
    }

    return p
  }

  /// Extracts path shapes from DOM.Path.
  private func extractPathShapes(_ path: DOM.Path, fill: Color?, stroke: StrokeStyle?, options: SVGOptions) -> [SVGShape] {
    var subPaths: [[Vector2]] = []
    var currentPath: [Vector2] = []
    // Track position in SVG coordinate space (unscaled)
    var svgPoint = DOM.Point(0, 0)
    var svgStartPoint = DOM.Point(0, 0)
    var lastControlPoint = DOM.Point(0, 0)

    for segment in path.segments {
      switch segment {
      case let .move(x, y, space):
        // Save current path if it exists
        if !currentPath.isEmpty {
          subPaths.append(currentPath)
          currentPath = []
        }

        svgPoint = space == .absolute ? DOM.Point(x, y) : DOM.Point(svgPoint.x + x, svgPoint.y + y)
        svgStartPoint = svgPoint
        currentPath.append(transform(svgPoint, options: options))

      case let .line(x, y, space):
        svgPoint = space == .absolute ? DOM.Point(x, y) : DOM.Point(svgPoint.x + x, svgPoint.y + y)
        currentPath.append(transform(svgPoint, options: options))

      case let .horizontal(x, space):
        svgPoint = space == .absolute ? DOM.Point(x, svgPoint.y) : DOM.Point(svgPoint.x + x, svgPoint.y)
        currentPath.append(transform(svgPoint, options: options))

      case let .vertical(y, space):
        svgPoint = space == .absolute ? DOM.Point(svgPoint.x, y) : DOM.Point(svgPoint.x, svgPoint.y + y)
        currentPath.append(transform(svgPoint, options: options))

      case let .cubic(x1: x1, y1: y1, x2: x2, y2: y2, x: x, y: y, space: space):
        let control1 = space == .absolute ? DOM.Point(x1, y1) : DOM.Point(svgPoint.x + x1, svgPoint.y + y1)
        let control2 = space == .absolute ? DOM.Point(x2, y2) : DOM.Point(svgPoint.x + x2, svgPoint.y + y2)
        let end = space == .absolute ? DOM.Point(x, y) : DOM.Point(svgPoint.x + x, svgPoint.y + y)

        let tessellated = tessellateCubicBezier(
          start: svgPoint,
          control1: control1,
          control2: control2,
          end: end,
          options: options
        )
        currentPath.append(contentsOf: tessellated)
        lastControlPoint = control2
        svgPoint = end

      case let .cubicSmooth(x2: x2, y2: y2, x: x, y: y, space: space):
        // First control point is reflection of last control point
        let control1 = DOM.Point(
          svgPoint.x + (svgPoint.x - lastControlPoint.x),
          svgPoint.y + (svgPoint.y - lastControlPoint.y)
        )
        let control2 = space == .absolute ? DOM.Point(x2, y2) : DOM.Point(svgPoint.x + x2, svgPoint.y + y2)
        let end = space == .absolute ? DOM.Point(x, y) : DOM.Point(svgPoint.x + x, svgPoint.y + y)

        let tessellated = tessellateCubicBezier(
          start: svgPoint,
          control1: control1,
          control2: control2,
          end: end,
          options: options
        )
        currentPath.append(contentsOf: tessellated)
        lastControlPoint = control2
        svgPoint = end

      case let .quadratic(x1, y1, x, y, space):
        let c = space == .absolute ? DOM.Point(x1, y1) : DOM.Point(svgPoint.x + x1, svgPoint.y + y1)
        let end = space == .absolute ? DOM.Point(x, y) : DOM.Point(svgPoint.x + x, svgPoint.y + y)

        let tessellated = tessellateQuadraticBezier(
          start: svgPoint,
          control: c,
          end: end,
          options: options
        )
        currentPath.append(contentsOf: tessellated)
        svgPoint = end

      case .quadraticSmooth:
        // Not implemented yet, skip
        break

      case let .arc(rx: rx, ry: ry, rotate: rotate, large: large, sweep: sweep, x: x, y: y, space: space):
        let end = space == .absolute ? DOM.Point(x, y) : DOM.Point(svgPoint.x + x, svgPoint.y + y)
        let tessellated = tessellateArc(
          start: svgPoint,
          rx: rx,
          ry: ry,
          rotation: rotate,
          largeArc: large,
          sweep: sweep,
          end: end,
          options: options
        )
        currentPath.append(contentsOf: tessellated)
        svgPoint = end

      case .close:
        if !currentPath.isEmpty {
          let transformedStart = transform(svgStartPoint, options: options)
          if currentPath.last != transformedStart {
            currentPath.append(transformedStart)
          }
          svgPoint = svgStartPoint
        }
      }
    }

    // Add the last path if it exists
    if !currentPath.isEmpty {
      subPaths.append(currentPath)
    }

    // Handle polygon holes using Polygon2D's built-in hole support
    if subPaths.count > 1, fill != nil, options.useHoles {
      // Check if inner paths should be holes (opposite winding from outer)
      let outerPacked = PackedVector2Array(subPaths[0])
      let outerClockwise = Geometry2D.isPolygonClockwise(polygon: outerPacked)

      // Combine all vertices and create polygon index arrays
      var allVertices: [Vector2] = []
      var polygonIndices: [PackedInt32Array] = []

      for (i, subPath) in subPaths.enumerated() {
        var vertices = subPath

        // For inner paths, ensure opposite winding for hole effect
        if i > 0 {
          let innerPacked = PackedVector2Array(subPath)
          let innerClockwise = Geometry2D.isPolygonClockwise(polygon: innerPacked)
          if innerClockwise == outerClockwise {
            // Reverse winding to create hole
            vertices = subPath.reversed()
          }
        }

        let startIndex = Int32(allVertices.count)
        let indices = PackedInt32Array((0 ..< vertices.count).map { startIndex + Int32($0) })
        polygonIndices.append(indices)
        allVertices.append(contentsOf: vertices)
      }

      return [.polygonWithHoles(vertices: allVertices, polygons: polygonIndices, fill: fill, stroke: stroke)]
    }

    // Default: render each subpath as a separate filled polygon
    return subPaths.map { vertices in
      .polygon(vertices: vertices, fill: fill, stroke: stroke)
    }
  }

  /// Extracts rectangle shape from DOM.Rect.
  private func extractRectShape(_ rect: DOM.Rect, fill: Color?, stroke: StrokeStyle?, options: SVGOptions) -> SVGShape {
    let x = rect.x ?? 0
    let y = rect.y ?? 0
    let w = rect.width
    let h = rect.height

    let vertices = [
      transform(DOM.Point(x, y), options: options),
      transform(DOM.Point(x + w, y), options: options),
      transform(DOM.Point(x + w, y + h), options: options),
      transform(DOM.Point(x, y + h), options: options),
    ]

    return .polygon(vertices: vertices, fill: fill, stroke: stroke)
  }

  /// Extracts circle shape from DOM.Circle.
  private func extractCircleShape(_ circle: DOM.Circle, fill: Color?, stroke: StrokeStyle?, options: SVGOptions) -> SVGShape {
    let cx = circle.cx ?? 0
    let cy = circle.cy ?? 0
    let r = circle.r

    let vertices = tessellateCircle(center: DOM.Point(cx, cy), radius: r, options: options)
    return .polygon(vertices: vertices, fill: fill, stroke: stroke)
  }

  /// Extracts ellipse shape from DOM.Ellipse.
  private func extractEllipseShape(_ ellipse: DOM.Ellipse, fill: Color?, stroke: StrokeStyle?, options: SVGOptions) -> SVGShape {
    let cx = ellipse.cx ?? 0
    let cy = ellipse.cy ?? 0
    let rx = ellipse.rx
    let ry = ellipse.ry

    let vertices = tessellateEllipse(center: DOM.Point(cx, cy), rx: rx, ry: ry, options: options)
    return .polygon(vertices: vertices, fill: fill, stroke: stroke)
  }

  /// Extracts line shape from DOM.Line.
  private func extractLineShape(_ line: DOM.Line, stroke: StrokeStyle?, options: SVGOptions) -> SVGShape {
    let vertices = [
      transform(DOM.Point(line.x1, line.y1), options: options),
      transform(DOM.Point(line.x2, line.y2), options: options),
    ]

    return .polygon(vertices: vertices, fill: nil, stroke: stroke)
  }

  /// Extracts polygon/polyline shape from DOM.Polygon or DOM.Polyline.
  private func extractPolygonShape(_ poly: DOM.GraphicsElement, fill: Color?, stroke: StrokeStyle?, options: SVGOptions, closed: Bool) -> SVGShape {
    var vertices: [Vector2] = []

    if let polygon = poly as? DOM.Polygon {
      vertices = polygon.points.map { transform($0, options: options) }
    } else if let polyline = poly as? DOM.Polyline {
      vertices = polyline.points.map { transform($0, options: options) }
    }

    if closed && !vertices.isEmpty && vertices.first != vertices.last {
      vertices.append(vertices[0])
    }

    return .polygon(vertices: vertices, fill: fill, stroke: stroke)
  }

  // MARK: Tessellation Helpers

  private func tessellateCircle(center: DOM.Point, radius: DOM.Coordinate, options: SVGOptions) -> [Vector2] {
    let segments = max(8, Int(Float(32) * options.tessellation))
    var vertices: [Vector2] = []

    for i in 0 ..< segments {
      let angle = Float(i) * 2.0 * .pi / Float(segments)
      let x = center.x + radius * cos(angle)
      let y = center.y + radius * sin(angle)
      vertices.append(transform(DOM.Point(x, y), options: options))
    }

    return vertices
  }

  private func tessellateEllipse(center: DOM.Point, rx: DOM.Coordinate, ry: DOM.Coordinate, options: SVGOptions) -> [Vector2] {
    let segments = max(8, Int(Float(32) * options.tessellation))
    var vertices: [Vector2] = []

    for i in 0 ..< segments {
      let angle = Float(i) * 2.0 * .pi / Float(segments)
      let x = center.x + rx * cos(angle)
      let y = center.y + ry * sin(angle)
      vertices.append(transform(DOM.Point(x, y), options: options))
    }

    return vertices
  }

  private func tessellateQuadraticBezier(
    start: DOM.Point,
    control: DOM.Point,
    end: DOM.Point,
    options: SVGOptions
  ) -> [Vector2] {
    // Convert quadratic to cubic: C1 = P0 + 2/3*(C-P0), C2 = P1 + 2/3*(C-P1)
    let ctrl1 = DOM.Point(
      start.x + 2.0 / 3.0 * (control.x - start.x),
      start.y + 2.0 / 3.0 * (control.y - start.y)
    )
    let ctrl2 = DOM.Point(
      end.x + 2.0 / 3.0 * (control.x - end.x),
      end.y + 2.0 / 3.0 * (control.y - end.y)
    )
    return tessellateCubicBezier(start: start, control1: ctrl1, control2: ctrl2, end: end, options: options)
  }

  private func tessellateCubicBezier(
    start: DOM.Point,
    control1: DOM.Point,
    control2: DOM.Point,
    end: DOM.Point,
    options: SVGOptions
  ) -> [Vector2] {
    let startVec = transform(start, options: options)
    let endVec = transform(end, options: options)
    let ctrl1Vec = transform(control1, options: options)
    let ctrl2Vec = transform(control2, options: options)

    let curve = Curve2D()
    // "out" control is relative to start point, "in" control is relative to end point
    curve.addPoint(position: startVec, in: .zero, out: ctrl1Vec - startVec)
    curve.addPoint(position: endVec, in: ctrl2Vec - endVec, out: .zero)

    // Adaptive tessellation - toleranceDegrees scaled by tessellation quality
    let tolerance = max(1.0, 8.0 / Double(options.tessellation))
    let baked = curve.tessellate(maxStages: 5, toleranceDegrees: tolerance)

    // Skip first point (duplicate of path's current position)
    var points: [Vector2] = []
    for i in 1 ..< Int(baked.size()) {
      points.append(baked[i])
    }
    return points
  }

  /// Tessellates an SVG arc into line segments.
  /// Converts from SVG endpoint parameterization to center parameterization.
  private func tessellateArc(
    start: DOM.Point,
    rx: Float,
    ry: Float,
    rotation: Float,
    largeArc: Bool,
    sweep: Bool,
    end: DOM.Point,
    options: SVGOptions
  ) -> [Vector2] {
    // Handle degenerate cases
    if start.x == end.x && start.y == end.y {
      return []
    }

    var rx = abs(rx)
    var ry = abs(ry)

    if rx == 0 || ry == 0 {
      // Degenerate to line
      return [transform(end, options: options)]
    }

    // Convert rotation to radians
    let phi = rotation * .pi / 180.0

    // Step 1: Compute (x1', y1') - transformed start point
    let dx = (start.x - end.x) / 2
    let dy = (start.y - end.y) / 2
    let cosPhi = cos(phi)
    let sinPhi = sin(phi)
    let x1p = cosPhi * dx + sinPhi * dy
    let y1p = -sinPhi * dx + cosPhi * dy

    // Step 2: Compute (cx', cy') - transformed center
    let x1p2 = x1p * x1p
    let y1p2 = y1p * y1p
    var rx2 = rx * rx
    var ry2 = ry * ry

    // Ensure radii are large enough
    let lambda = x1p2 / rx2 + y1p2 / ry2
    if lambda > 1 {
      let sqrtLambda = sqrt(lambda)
      rx *= sqrtLambda
      ry *= sqrtLambda
      rx2 = rx * rx
      ry2 = ry * ry
    }

    let num = rx2 * ry2 - rx2 * y1p2 - ry2 * x1p2
    let denom = rx2 * y1p2 + ry2 * x1p2

    var sq: Float = 0
    if denom > 0 {
      sq = max(0, num / denom)
    }
    sq = sqrt(sq)

    if largeArc == sweep {
      sq = -sq
    }

    let cxp = sq * rx * y1p / ry
    let cyp = -sq * ry * x1p / rx

    // Step 3: Compute (cx, cy) from (cx', cy')
    let cx = cosPhi * cxp - sinPhi * cyp + (start.x + end.x) / 2
    let cy = sinPhi * cxp + cosPhi * cyp + (start.y + end.y) / 2

    // Step 4: Compute theta1 and dtheta
    func angle(ux: Float, uy: Float, vx: Float, vy: Float) -> Float {
      let dot = ux * vx + uy * vy
      let len = sqrt(ux * ux + uy * uy) * sqrt(vx * vx + vy * vy)
      var ang = acos(max(-1, min(1, dot / len)))
      if ux * vy - uy * vx < 0 {
        ang = -ang
      }
      return ang
    }

    let theta1 = angle(ux: 1, uy: 0, vx: (x1p - cxp) / rx, vy: (y1p - cyp) / ry)
    var dtheta = angle(
      ux: (x1p - cxp) / rx,
      uy: (y1p - cyp) / ry,
      vx: (-x1p - cxp) / rx,
      vy: (-y1p - cyp) / ry
    )

    // Adjust dtheta based on sweep flag
    if !sweep, dtheta > 0 {
      dtheta -= 2 * .pi
    } else if sweep, dtheta < 0 {
      dtheta += 2 * .pi
    }

    // Step 5: Tessellate the arc
    let steps = max(4, Int(abs(dtheta) / (Float.pi / 16) * options.tessellation))
    var points: [Vector2] = []

    for i in 1 ... steps {
      let t = Float(i) / Float(steps)
      let theta = theta1 + t * dtheta

      // Point on unit circle
      let cosTheta = cos(theta)
      let sinTheta = sin(theta)

      // Scale by radii and rotate
      let px = cosPhi * rx * cosTheta - sinPhi * ry * sinTheta + cx
      let py = sinPhi * rx * cosTheta + cosPhi * ry * sinTheta + cy

      points.append(transform(DOM.Point(px, py), options: options))
    }

    return points
  }
}
