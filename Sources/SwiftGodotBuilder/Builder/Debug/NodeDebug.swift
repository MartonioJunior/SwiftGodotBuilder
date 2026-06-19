import Foundation
import SwiftGodot

/// Debug utility for detecting node creation/destruction issues.
///
/// Automatically warns about:
/// - High node churn (creating/destroying many nodes per second)
/// - Steadily growing node counts (potential leaks)
/// - Specific GView types being over-instantiated
///
/// ## Usage
///
/// Enable at app startup:
/// ```swift
/// NodeDebug.isEnabled = true
/// ```
///
/// Logs warnings like:
/// ```
/// ⚠️ [NodeDebug] High churn: 45 nodes created/sec (EnemyView: 30, BulletView: 15)
/// ⚠️ [NodeDebug] Node count growing: 250 -> 380 in 10sec (+13/sec)
/// ```
public enum NodeDebug {
  /// Enable/disable node debugging.
  public nonisolated(unsafe) static var isEnabled = false

  /// Nodes created per second threshold before warning.
  public nonisolated(unsafe) static var churnWarningThreshold: Int = 30

  /// Seconds between growth checks.
  public nonisolated(unsafe) static var growthCheckInterval: Double = 10.0

  /// Minimum growth rate (nodes/sec) to warn about.
  public nonisolated(unsafe) static var growthWarningThreshold: Double = 5.0

  /// Cooldown between repeated warnings (seconds).
  public nonisolated(unsafe) static var reportCooldown: Double = 10.0

  /// Number of consecutive high-churn windows required before warning.
  /// This filters out initial spikes from level loads.
  public nonisolated(unsafe) static var sustainedChurnWindows: Int = 3

  // Internal tracking
  private nonisolated(unsafe) static var creationCounts: [String: Int] = [:]
  private nonisolated(unsafe) static var destructionCount: Int = 0
  private nonisolated(unsafe) static var windowStart: Double = 0
  private nonisolated(unsafe) static var lastReportTime: Double = 0
  private nonisolated(unsafe) static var lastGrowthCheckTime: Double = 0
  private nonisolated(unsafe) static var lastNodeCount: Int = 0
  private nonisolated(unsafe) static var consecutiveHighChurnWindows: Int = 0
  private static let lock = NSLock()

  /// Record a node creation. Call from GNode.toNode() or GView instantiation.
  ///
  /// - Parameter viewType: The GView or node type name being created
  public static func recordCreation(viewType: String) {
    guard isEnabled else { return }

    let now = currentTime()

    lock.lock()
    defer { lock.unlock() }

    // Initialize window if needed
    if windowStart == 0 {
      windowStart = now
      lastGrowthCheckTime = now
    }

    creationCounts[viewType, default: 0] += 1

    // Check rates every second
    let elapsed = now - windowStart
    if elapsed >= 1.0 {
      let totalCreations = creationCounts.values.reduce(0, +)

      // Track consecutive high-churn windows
      if totalCreations > churnWarningThreshold {
        consecutiveHighChurnWindows += 1

        // Only warn if sustained over multiple windows (filters out level load spikes)
        if consecutiveHighChurnWindows >= sustainedChurnWindows, (now - lastReportTime) > reportCooldown {
          let topTypes = creationCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")

          GD.printErr("⚠️ [NodeDebug] Sustained high churn: \(totalCreations) nodes/sec for \(consecutiveHighChurnWindows)s (\(topTypes))")
          lastReportTime = now
        }
      } else {
        // Reset counter when churn drops below threshold
        consecutiveHighChurnWindows = 0
      }

      // Reset window
      creationCounts.removeAll(keepingCapacity: true)
      windowStart = now
    }

    // Periodic growth check
    checkGrowth(now: now)
  }

  /// Record a node destruction.
  public static func recordDestruction() {
    guard isEnabled else { return }

    lock.lock()
    defer { lock.unlock() }
    destructionCount += 1
  }

  /// Check for steadily growing node count (potential leak).
  private static func checkGrowth(now: Double) {
    guard now - lastGrowthCheckTime >= growthCheckInterval else { return }

    // Get current node count from scene tree
    guard let tree = Engine.getMainLoop() as? SceneTree else { return }

    let root = tree.root
    let currentCount = countNodes(root)

    if lastNodeCount > 0 {
      let growth = currentCount - lastNodeCount
      let growthRate = Double(growth) / growthCheckInterval

      if growthRate > growthWarningThreshold, (now - lastReportTime) > reportCooldown {
        GD.printErr("⚠️ [NodeDebug] Node count growing: \(lastNodeCount) → \(currentCount) in \(Int(growthCheckInterval))sec (+\(String(format: "%.1f", growthRate))/sec)")
        lastReportTime = now
      }
    }

    lastNodeCount = currentCount
    lastGrowthCheckTime = now
  }

  /// Count all nodes in tree recursively.
  private static func countNodes(_ node: Node) -> Int {
    var count = 1
    for i in 0 ..< node.getChildCount() {
      if let child = node.getChild(idx: i) {
        count += countNodes(child)
      }
    }
    return count
  }

  /// Get current statistics.
  public static func currentStats() -> (nodeCount: Int, recentCreations: [String: Int]) {
    lock.lock()
    defer { lock.unlock() }

    var nodeCount = 0
    if let tree = Engine.getMainLoop() as? SceneTree
    {
      let root = tree.root
      nodeCount = countNodes(root)
    }

    return (nodeCount, creationCounts)
  }

  /// Print current node tree summary.
  public static func printSummary() {
    guard let tree = Engine.getMainLoop() as? SceneTree else {
      GD.print("[NodeDebug] No scene tree available")
      return
    }

    let root = tree.root
    let count = countNodes(root)
    GD.print("[NodeDebug] Total nodes in tree: \(count)")

    // Count by type
    var typeCounts: [String: Int] = [:]
    countNodesByType(root, counts: &typeCounts)

    let sorted = typeCounts.sorted { $0.value > $1.value }.prefix(10)
    for (type, count) in sorted {
      GD.print("  \(count)x \(type)")
    }
  }

  private static func countNodesByType(_ node: Node, counts: inout [String: Int]) {
    let typeName = String(describing: type(of: node))
    counts[typeName, default: 0] += 1

    for i in 0 ..< node.getChildCount() {
      if let child = node.getChild(idx: i) {
        countNodesByType(child, counts: &counts)
      }
    }
  }

  /// Reset all tracking data.
  public static func reset() {
    lock.lock()
    defer { lock.unlock() }
    creationCounts.removeAll()
    destructionCount = 0
    windowStart = 0
    lastReportTime = 0
    lastGrowthCheckTime = 0
    lastNodeCount = 0
    consecutiveHighChurnWindows = 0
  }

  private static func currentTime() -> Double {
    ProcessInfo.processInfo.systemUptime
  }
}
