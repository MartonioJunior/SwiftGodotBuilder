// SwiftGodotBuilderTestRunner.swift
// CLI tool that builds the test extension, launches Godot, and reports results

import Foundation

@main
struct SwiftGodotBuilderTestRunner {
  static func main() async {
    let projectPath = "Tests/SwiftGodotBuilderTestProject"
    let resultsPath = "Tests/SwiftGodotBuilderTestProject/test_results.json"
    let extensionTarget = "SwiftGodotBuilderTestExtension"
    let buildConfiguration = "debug"

    print("SwiftGodotBuilder Test Runner")
    print(String(repeating: "=", count: 60))

    let cwd = FileManager.default.currentDirectoryPath
    let absoluteProjectPath = projectPath.hasPrefix("/") ? projectPath : "\(cwd)/\(projectPath)"
    let absoluteResultsPath = resultsPath.hasPrefix("/") ? resultsPath : "\(cwd)/\(resultsPath)"

    print("\nPaths:")
    print("  Working directory: \(cwd)")
    print("  Project path:      \(absoluteProjectPath)")
    print("  Results path:      \(absoluteResultsPath)")

    // Find swift executable
    let swiftPath = findExecutable("swift")
    guard let swiftPath else {
      print("Swift not found in PATH")
      exit(1)
    }

    // 1. Build the test extension and dependencies
    print("\n[1/5] Building test extension...")
    let products = [extensionTarget, "SwiftGodotBuilder", "SwiftGodot"]
    for product in products {
      let success = runProcess(
        executable: swiftPath,
        arguments: ["build", "--product", product, "-c", buildConfiguration],
        workingDirectory: cwd
      )
      if !success {
        print("      Build failed for \(product)")
        exit(1)
      }
    }
    print("      Build successful")

    // 2. Copy built libraries to Godot project
    print("\n[2/5] Copying libraries to test project...")
    let fm = FileManager.default
    let destDir = "\(projectPath)/bin"
    try? fm.createDirectory(atPath: destDir, withIntermediateDirectories: true)

    #if os(macOS)
      let libPrefix = "lib"
      let libExt = "dylib"
      #if arch(arm64)
        let platformDir = "arm64-apple-macosx"
      #else
        let platformDir = "x86_64-apple-macosx"
      #endif
    #elseif os(Linux)
      let libPrefix = "lib"
      let libExt = "so"
      #if arch(arm64)
        let platformDir = "aarch64-unknown-linux-gnu"
      #else
        let platformDir = "x86_64-unknown-linux-gnu"
      #endif
    #else
      let libPrefix = "lib"
      let libExt = "dylib"
      let platformDir = ""
    #endif

    let libraryNames = [extensionTarget, "SwiftGodotBuilder", "SwiftGodot"]
    let platformBuildDir = ".build/\(platformDir)/\(buildConfiguration)"
    let simpleBuildDir = ".build/\(buildConfiguration)"

    for name in libraryNames {
      let libName = "\(libPrefix)\(name).\(libExt)"
      let platformSource = "\(platformBuildDir)/\(libName)"
      let simpleSource = "\(simpleBuildDir)/\(libName)"

      let source: String
      if fm.fileExists(atPath: platformSource) {
        source = platformSource
      } else if fm.fileExists(atPath: simpleSource) {
        source = simpleSource
      } else {
        print("      Library not found: \(platformSource) or \(simpleSource)")
        exit(1)
      }

      let dest = "\(destDir)/\(libName)"
      do {
        if fm.fileExists(atPath: dest) {
          try fm.removeItem(atPath: dest)
        }
        try fm.copyItem(atPath: source, toPath: dest)
        print("      Copied \(libName)")
      } catch {
        print("      Copy failed: \(error)")
        exit(1)
      }
    }
    print("      Copy successful")

    // Find godot
    let godotPath = findExecutable("godot")
    guard let godotPath else {
      print("      Godot not found in PATH")
      exit(1)
    }

    // 3. Import project
    print("\n[3/5] Importing Godot project...")
    _ = runProcess(
      executable: godotPath,
      arguments: ["--headless", "--import", "--path", absoluteProjectPath],
      workingDirectory: absoluteProjectPath
    )
    print("      Import complete")

    // 4. Launch Godot
    print("\n[4/5] Running tests in Godot...")
    let godotSuccess = runProcess(
      executable: godotPath,
      arguments: ["--headless", "--path", absoluteProjectPath],
      workingDirectory: absoluteProjectPath
    )

    // 5. Read and report results
    print("\n[5/5] Reading results...")
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: absoluteResultsPath))
      let decoder = JSONDecoder()
      let results = try decoder.decode(TestResults.self, from: data)

      print("\n" + String(repeating: "=", count: 60))
      print("Test Results")
      print(String(repeating: "=", count: 60))

      for suite in results.suites {
        print("\n\(suite.name):")
        for test in suite.tests {
          let icon = test.status == "passed" ? "+" : (test.status == "failed" ? "x" : "-")
          let duration = test.duration >= 1.0
            ? String(format: "%.2fs", test.duration)
            : String(format: "%.2fms", test.duration * 1000)
          print("  [\(icon)] \(test.name) (\(duration))")
          if let failure = test.failure {
            print("      \(failure.message)")
            print("      at \(failure.file):\(failure.line)")
          }
        }
      }

      let totalDuration = results.duration >= 1.0
        ? String(format: "%.2fs", results.duration)
        : String(format: "%.2fms", results.duration * 1000)
      print("\n" + String(repeating: "-", count: 60))
      print("Summary: \(results.summary.passed) passed, \(results.summary.failed) failed, \(results.summary.skipped) skipped")
      print("Total time: \(totalDuration)")
      print(String(repeating: "=", count: 60))

      exit(results.summary.failed > 0 ? 1 : 0)
    } catch {
      print("      Failed to read results: \(error)")
      exit(godotSuccess ? 0 : 1)
    }
  }

  static func findExecutable(_ name: String) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = [name]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    do {
      try process.run()
      process.waitUntilExit()
      if process.terminationStatus != 0 { return nil }
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
      return nil
    }
  }

  static func runProcess(executable: String, arguments: [String], workingDirectory: String) -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    do {
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus == 0
    } catch {
      return false
    }
  }
}

// MARK: - Result Types for JSON decoding

struct TestResults: Codable {
  let suites: [TestSuiteResult]
  let duration: Double
  let summary: TestSummary
}

struct TestSuiteResult: Codable {
  let name: String
  let tests: [TestCaseResult]
}

struct TestCaseResult: Codable {
  let name: String
  let status: String
  let duration: Double
  let failure: TestFailure?
}

struct TestFailure: Codable {
  let message: String
  let file: String
  let line: Int
}

struct TestSummary: Codable {
  let passed: Int
  let failed: Int
  let skipped: Int
}
