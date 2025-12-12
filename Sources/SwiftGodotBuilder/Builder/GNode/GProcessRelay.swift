import SwiftGodot

/// A hidden node that relays process and ready calls to closures.
/// Used by `GNode` extensions onProcess, onPhysicsProcess, onReady.
@_documentation(visibility: private)
@Godot
public final class GProcessRelay: Node {
  public var ownerNode: Weak<Node> = .init(nil)
  public var onReadyCall: ((Node) -> Void)?
  public var onProcessCall: ((Node, Double) -> Void)?
  public var onPhysicsCall: ((Node, Double) -> Void)?

  override public func _ready() {
    if onProcessCall == nil { setProcess(enable: false) } else { setProcess(enable: true) }
    if onPhysicsCall == nil { setPhysicsProcess(enable: false) } else { setPhysicsProcess(enable: true) }
    guard let host = ownerNode.value else { return }
    onReadyCall?(host)
  }

  override public func _process(delta: Double) {
    guard let host = ownerNode.value else { return }
    let source = String(describing: type(of: host))
    let start = ProcessDebug.beginProcess(source: source)
    onProcessCall?(host, delta)
    ProcessDebug.endProcess(startTime: start, source: source)
  }

  override public func _physicsProcess(delta: Double) {
    guard let host = ownerNode.value else { return }
    let source = "\(String(describing: type(of: host))).physics"
    let start = ProcessDebug.beginProcess(source: source)
    onPhysicsCall?(host, delta)
    ProcessDebug.endProcess(startTime: start, source: source)
  }
}
