// ObjectPoolTests.swift
// Runtime tests for ObjectPool

import SwiftGodot
import SwiftGodotBuilder

// Test pooled object that tracks lifecycle calls
final class PooledNode: Node2D, PooledObject {
  static var acquireCount = 0
  static var releaseCount = 0

  static func reset() {
    acquireCount = 0
    releaseCount = 0
  }

  func onAcquire() {
    PooledNode.acquireCount += 1
  }

  func onRelease() {
    PooledNode.releaseCount += 1
  }
}

struct ObjectPoolTests: TestSuite {
  static var registeredTypes: [Object.Type] { [PooledNode.self] }

  var allTests: [TestInvocation] {
    [
      test("testFactoryCreatesInstances", testFactoryCreatesInstances),
      test("testPreloadFillsPool", testPreloadFillsPool),
      test("testAcquireFromPool", testAcquireFromPool),
      test("testAcquireCallsOnAcquire", testAcquireCallsOnAcquire),
      test("testReleaseCallsOnRelease", testReleaseCallsOnRelease),
      test("testReleaseReturnsToPool", testReleaseReturnsToPool),
      test("testPoolCapacityLimit", testPoolCapacityLimit),
      test("testAcquireReleaseMultipleCycles", testAcquireReleaseMultipleCycles),
      test("testAvailableCount", testAvailableCount),
    ]
  }

  func testFactoryCreatesInstances() {
    var createCount = 0
    let pool = ObjectPool<Node2D>(factory: {
      createCount += 1
      return Node2D()
    })

    let node = pool.acquire()
    XCTAssertNotNil(node, "Factory should create instance")
    XCTAssertEqual(createCount, 1, "Factory called once")
  }

  func testPreloadFillsPool() {
    var createCount = 0
    let pool = ObjectPool<Node2D>(factory: {
      createCount += 1
      return Node2D()
    })

    pool.preload(5)

    XCTAssertEqual(createCount, 5, "Preload should create 5 instances")
    XCTAssertEqual(pool.availableCount, 5, "Pool should have 5 available")
  }

  func testAcquireFromPool() {
    var createCount = 0
    let pool = ObjectPool<Node2D>(factory: {
      createCount += 1
      return Node2D()
    })

    pool.preload(3)
    XCTAssertEqual(createCount, 3)

    _ = pool.acquire()
    XCTAssertEqual(createCount, 3, "Acquire from pool should not create new")
    XCTAssertEqual(pool.availableCount, 2, "Pool should have 2 left")
  }

  func testAcquireCallsOnAcquire() {
    PooledNode.reset()
    let pool = ObjectPool<PooledNode>(factory: { PooledNode() })

    pool.preload(1)
    XCTAssertEqual(PooledNode.acquireCount, 0, "onAcquire not called during preload")

    let node = pool.acquire()
    XCTAssertEqual(PooledNode.acquireCount, 1, "onAcquire called on acquire")
  }

  func testReleaseCallsOnRelease() {
    PooledNode.reset()
    let pool = ObjectPool<PooledNode>(factory: { PooledNode() })

    let node = pool.acquire()!
    let releaseCountBefore = PooledNode.releaseCount

    pool.release(node)

    XCTAssertEqual(PooledNode.releaseCount, releaseCountBefore + 1, "onRelease called on release")
  }

  func testReleaseReturnsToPool() {
    var createCount = 0
    let pool = ObjectPool<Node2D>(factory: {
      createCount += 1
      return Node2D()
    })

    let node = pool.acquire()!
    XCTAssertEqual(pool.availableCount, 0)

    pool.release(node)
    XCTAssertEqual(pool.availableCount, 1, "Released node returns to pool")

    // Acquire again should reuse
    _ = pool.acquire()
    XCTAssertEqual(createCount, 1, "Reused pooled instance")
  }

  func testPoolCapacityLimit() {
    let pool = ObjectPool<Node2D>(factory: { Node2D() }, max: 2)

    pool.preload(5)
    XCTAssertEqual(pool.availableCount, 2, "Pool should respect max limit")
  }

  func testAcquireReleaseMultipleCycles() {
    var createCount = 0
    let pool = ObjectPool<Node2D>(factory: {
      createCount += 1
      return Node2D()
    })

    // Cycle 1
    let n1 = pool.acquire()!
    let n2 = pool.acquire()!
    pool.release(n1)
    pool.release(n2)

    // Cycle 2 - should reuse
    _ = pool.acquire()
    _ = pool.acquire()

    XCTAssertEqual(createCount, 2, "Should only create 2 instances across cycles")
  }

  func testAvailableCount() {
    let pool = ObjectPool<Node2D>(factory: { Node2D() })

    XCTAssertEqual(pool.availableCount, 0, "Initial count is 0")

    pool.preload(3)
    XCTAssertEqual(pool.availableCount, 3)

    _ = pool.acquire()
    XCTAssertEqual(pool.availableCount, 2)

    _ = pool.acquire()
    XCTAssertEqual(pool.availableCount, 1)

    let node = pool.acquire()!
    XCTAssertEqual(pool.availableCount, 0)

    pool.release(node)
    XCTAssertEqual(pool.availableCount, 1)
  }
}
