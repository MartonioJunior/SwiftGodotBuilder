import Foundation
import SwiftGodot

/// Debug utility for detecting reactive state that updates too frequently.
///
/// Enable debugging to detect performance issues like:
/// - State properties updated every frame unnecessarily
/// - Computed properties that depend on frequently-changing values
/// - watchAny() on objects with per-frame position updates
/// - `.computed()` called repeatedly (should be in init, not computed property)
///
/// ## Usage
///
/// Enable at app startup:
/// ```swift
/// ReactiveDebug.isEnabled = true
/// ReactiveDebug.warningThreshold = 30 // warns if >30 updates/sec
/// ```
///
/// The debug system will log warnings like:
/// ```
/// [ReactiveDebug] Hot observer: 60.0/sec at PlayerView.swift:42 (position)
/// [ReactiveDebug] Repeated .computed() creation: 60.0/sec at LevelView.swift:15
/// ```
public enum ReactiveDebug {
  /// Enable/disable reactive debugging. Disabled by default for performance.
  public nonisolated(unsafe) static var isEnabled = false

  /// Updates per second threshold before warning. Default is 30.
  public nonisolated(unsafe) static var warningThreshold: Double = 30

  /// Minimum time between reports for the same observer (seconds).
  public nonisolated(unsafe) static var reportCooldown: Double = 5.0

  /// Internal tracking data (protected by lock)
  private nonisolated(unsafe) static var observerStats: [String: ObserverStats] = [:]
  private nonisolated(unsafe) static var computedCreationStats: [String: CreationStats] = [:]
  private static let lock = NSLock()

  private struct ObserverStats {
    var callCount: Int = 0
    var windowStart: Double = 0
    var lastReportTime: Double = 0
    let label: String

    init(label: String) {
      self.label = label
      windowStart = currentTime()
    }
  }

  private struct CreationStats {
    var callCount: Int = 0
    var windowStart: Double = 0
    var lastReportTime: Double = 0
    let label: String

    init(label: String) {
      self.label = label
      windowStart = currentTime()
    }
  }

  /// Record a .computed() creation. Warns if same call site creates many instances.
  ///
  /// This detects the anti-pattern of putting .computed() in a computed property:
  /// ```swift
  /// // BAD - creates new State on every access
  /// var isActive: State<Bool> { router.computed(\.scene.isActive) }
  ///
  /// // GOOD - created once in init
  /// let isActive: State<Bool>
  /// init(...) { isActive = router.computed(\.scene.isActive) }
  /// ```
  ///
  /// - Parameters:
  ///   - file: Source file (use #file)
  ///   - line: Source line (use #line)
  public static func recordComputedCreation(
    file: String = #file,
    line: Int = #line
  ) {
    guard isEnabled else { return }

    let key = "\(file):\(line)"
    let now = currentTime()

    lock.lock()
    defer { lock.unlock() }

    if computedCreationStats[key] == nil {
      let filename = shortFilename(file)
      computedCreationStats[key] = CreationStats(label: "\(filename):\(line)")
    }

    var stats = computedCreationStats[key]!
    stats.callCount += 1

    // Check rate every second
    let elapsed = now - stats.windowStart
    if elapsed >= 1.0 {
      let rate = Double(stats.callCount) / elapsed

      // Warn if creating more than 1/sec (should be created once in init)
      if rate > 1.0, (now - stats.lastReportTime) > reportCooldown {
        GD.printErr("⚠️ [ReactiveDebug] Repeated .computed() creation: \(String(format: "%.1f", rate))/sec at \(stats.label) - move to init")
        stats.lastReportTime = now
      }

      // Reset window
      stats.callCount = 0
      stats.windowStart = now
    }

    computedCreationStats[key] = stats
  }

  /// Record when a computed State fires an update to listeners.
  ///
  /// This detects computed states that update too frequently, which may indicate:
  /// - Source state changing every frame (e.g., position bound to computed)
  /// - Computed depending on frequently-changing values
  ///
  /// - Parameters:
  ///   - file: Source file where computed State was created
  ///   - line: Source line where computed State was created
  public static func recordComputedUpdate(
    file: String,
    line: Int
  ) {
    guard isEnabled else { return }

    let key = "update:\(file):\(line)"
    let now = currentTime()

    lock.lock()
    defer { lock.unlock() }

    if computedCreationStats[key] == nil {
      let filename = shortFilename(file)
      computedCreationStats[key] = CreationStats(label: "\(filename):\(line)")
    }

    var stats = computedCreationStats[key]!
    stats.callCount += 1

    // Check rate every second
    let elapsed = now - stats.windowStart
    if elapsed >= 1.0 {
      let rate = Double(stats.callCount) / elapsed

      // Warn if updating more than threshold/sec
      if rate > warningThreshold, (now - stats.lastReportTime) > reportCooldown {
        GD.printErr("⚠️ [ReactiveDebug] Hot computed state: \(String(format: "%.1f", rate))/sec at \(stats.label)")
        stats.lastReportTime = now
      }

      // Reset window
      stats.callCount = 0
      stats.windowStart = now
    }

    computedCreationStats[key] = stats
  }

  /// Record a state change. Call this when reactive state notifies listeners.
  ///
  /// - Parameters:
  ///   - label: Human-readable label (e.g., property name)
  ///   - file: Source file where state was created
  ///   - line: Source line where state was created
  public static func recordStateChange(
    label: String?,
    file: String,
    line: Int
  ) {
    guard isEnabled else { return }

    let key = "\(file):\(line)"
    let now = currentTime()

    lock.lock()
    defer { lock.unlock() }

    if observerStats[key] == nil {
      let filename = shortFilename(file)
      let displayLabel = label ?? "\(filename):\(line)"
      observerStats[key] = ObserverStats(label: displayLabel)
    }

    var stats = observerStats[key]!
    stats.callCount += 1

    // Check rate every second
    let elapsed = now - stats.windowStart
    if elapsed >= 1.0 {
      let rate = Double(stats.callCount) / elapsed

      if rate > warningThreshold, (now - stats.lastReportTime) > reportCooldown {
        GD.printErr("⚠️ [ReactiveDebug] Hot state: \(String(format: "%.1f", rate))/sec - \(stats.label)")
        stats.lastReportTime = now
      }

      // Reset window
      stats.callCount = 0
      stats.windowStart = now
    }

    observerStats[key] = stats
  }

  /// Record an observable property change.
  ///
  /// - Parameters:
  ///   - objectType: Type name of the observable object
  ///   - keyPath: String representation of the key path
  public static func recordObservableChange(
    objectType: String,
    keyPath: String
  ) {
    guard isEnabled else { return }

    let key = "\(objectType).\(keyPath)"
    let now = currentTime()

    lock.lock()
    defer { lock.unlock() }

    if observerStats[key] == nil {
      observerStats[key] = ObserverStats(label: key)
    }

    var stats = observerStats[key]!
    stats.callCount += 1

    // Check rate every second
    let elapsed = now - stats.windowStart
    if elapsed >= 1.0 {
      let rate = Double(stats.callCount) / elapsed

      if rate > warningThreshold, (now - stats.lastReportTime) > reportCooldown {
        GD.printErr("⚠️ [ReactiveDebug] Hot observable: \(String(format: "%.1f", rate))/sec - \(stats.label)")
        stats.lastReportTime = now
      }

      // Reset window
      stats.callCount = 0
      stats.windowStart = now
    }

    observerStats[key] = stats
  }

  /// Get current stats for all tracked observers.
  /// Returns array of (label, currentRate) tuples.
  public static func currentStats() -> [(String, Double)] {
    guard isEnabled else { return [] }

    lock.lock()
    defer { lock.unlock() }

    let now = currentTime()
    return observerStats.map { _, stats in
      let elapsed = max(now - stats.windowStart, 0.001)
      let rate = Double(stats.callCount) / elapsed
      return (stats.label, rate)
    }.sorted { $0.1 > $1.1 }
  }

  /// Print a summary of all observers sorted by frequency.
  public static func printSummary() {
    let stats = currentStats()
    guard !stats.isEmpty else {
      GD.print("[ReactiveDebug] No observers tracked")
      return
    }

    GD.print("[ReactiveDebug] Observer frequency summary:")
    for (label, rate) in stats.prefix(20) {
      let marker = rate > warningThreshold ? "⚠️" : "  "
      GD.print("\(marker) \(String(format: "%6.1f", rate))/sec - \(label)")
    }
  }

  /// Reset all tracking data.
  public static func reset() {
    lock.lock()
    defer { lock.unlock() }
    observerStats.removeAll()
    computedCreationStats.removeAll()
  }

  private static func currentTime() -> Double {
    ProcessInfo.processInfo.systemUptime
  }

  private static func shortFilename(_ path: String) -> String {
    (path as NSString).lastPathComponent
  }
}
