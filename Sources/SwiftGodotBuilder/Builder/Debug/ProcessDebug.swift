import Foundation
import SwiftGodot

/// Debug utility for detecting slow process callbacks.
///
/// Automatically warns when `onProcess` or `onPhysicsProcess` callbacks
/// take longer than expected, which can cause frame drops.
///
/// ## Usage
///
/// Enable at app startup:
/// ```swift
/// ProcessDebug.isEnabled = true
/// ```
///
/// Logs warnings like:
/// ```
/// ⚠️ [ProcessDebug] Slow onProcess: 8.5ms at EnemyView (budget: 2ms)
/// ⚠️ [ProcessDebug] Consistently slow: PlayerView averaging 4.2ms/frame
/// ```
public enum ProcessDebug {
  /// Enable/disable process debugging.
  public nonisolated(unsafe) static var isEnabled = false

  /// Single-frame warning threshold in milliseconds.
  public nonisolated(unsafe) static var spikeThresholdMs: Double = 5.0

  /// Average time threshold for "consistently slow" warnings.
  public nonisolated(unsafe) static var averageThresholdMs: Double = 2.0

  /// Number of samples to average before checking.
  public nonisolated(unsafe) static var sampleWindow: Int = 60

  /// Cooldown between repeated warnings for same source (seconds).
  public nonisolated(unsafe) static var reportCooldown: Double = 5.0

  // Internal tracking
  private nonisolated(unsafe) static var processStats: [String: ProcessStats] = [:]
  private static let lock = NSLock()

  private struct ProcessStats {
    var samples: [Double] = []
    var lastSpikeReport: Double = 0
    var lastAverageReport: Double = 0

    mutating func addSample(_ ms: Double, maxSamples: Int) {
      samples.append(ms)
      if samples.count > maxSamples {
        samples.removeFirst()
      }
    }

    var average: Double {
      guard !samples.isEmpty else { return 0 }
      return samples.reduce(0, +) / Double(samples.count)
    }
  }

  /// Begin timing a process callback. Returns a token to pass to `endProcess`.
  ///
  /// - Parameter source: Identifier for the source (e.g., view type name)
  /// - Returns: Start time token
  public static func beginProcess(source _: String) -> Double? {
    guard isEnabled else { return nil }
    return currentTime()
  }

  /// End timing a process callback and record the duration.
  ///
  /// - Parameters:
  ///   - startTime: Token from `beginProcess`
  ///   - source: Same identifier passed to `beginProcess`
  public static func endProcess(startTime: Double?, source: String) {
    guard isEnabled, let start = startTime else { return }

    let elapsed = currentTime() - start
    let elapsedMs = elapsed * 1000.0
    let now = currentTime()

    lock.lock()
    defer { lock.unlock() }

    if processStats[source] == nil {
      processStats[source] = ProcessStats()
    }

    processStats[source]!.addSample(elapsedMs, maxSamples: sampleWindow)

    // Check for spike
    if elapsedMs > spikeThresholdMs {
      if (now - processStats[source]!.lastSpikeReport) > reportCooldown {
        GD.printErr("⚠️ [ProcessDebug] Slow onProcess: \(String(format: "%.1f", elapsedMs))ms at \(source) (budget: \(String(format: "%.0f", spikeThresholdMs))ms)")
        processStats[source]!.lastSpikeReport = now
      }
    }

    // Check for consistently slow (after enough samples)
    if processStats[source]!.samples.count >= sampleWindow {
      let avg = processStats[source]!.average
      if avg > averageThresholdMs {
        if (now - processStats[source]!.lastAverageReport) > reportCooldown * 2 {
          GD.printErr("⚠️ [ProcessDebug] Consistently slow: \(source) averaging \(String(format: "%.1f", avg))ms/frame")
          processStats[source]!.lastAverageReport = now
        }
      }
    }
  }

  /// Get current statistics for all tracked sources.
  public static func currentStats() -> [(source: String, averageMs: Double, sampleCount: Int)] {
    lock.lock()
    defer { lock.unlock() }

    return processStats.map { source, stats in
      (source, stats.average, stats.samples.count)
    }.sorted { $0.averageMs > $1.averageMs }
  }

  /// Print summary of process timing.
  public static func printSummary() {
    let stats = currentStats()
    guard !stats.isEmpty else {
      GD.print("[ProcessDebug] No process callbacks tracked")
      return
    }

    GD.print("[ProcessDebug] Process callback timing:")
    for (source, avgMs, samples) in stats.prefix(10) {
      let marker = avgMs > averageThresholdMs ? "⚠️" : "  "
      GD.print("\(marker) \(String(format: "%5.2f", avgMs))ms avg - \(source) (\(samples) samples)")
    }
  }

  /// Reset all tracking data.
  public static func reset() {
    lock.lock()
    defer { lock.unlock() }
    processStats.removeAll()
  }

  private static func currentTime() -> Double {
    ProcessInfo.processInfo.systemUptime
  }
}
