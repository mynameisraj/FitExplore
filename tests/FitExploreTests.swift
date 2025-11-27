// Copyright © 2025 Raj Ramamurthy.

import Foundation
import Synchronization
import Testing
@testable import FitExplore

struct FitExploreTests {
  enum TestError: Error {
    case missingFile
  }

  static let testModel = Mutex<DocumentModel?>(nil)

  func loadTestModel() throws -> DocumentModel {
    return try Self.testModel.withLock {
      if let model = $0 { return model }

      guard let fileURL =
        Bundle.tests.url(forResource: "test-run", withExtension: "fit")
      else {
        Issue.record("test-run.fit not found in test bundle")
        throw TestError.missingFile
      }

      let data = try Data(contentsOf: fileURL)
      let model = try DocumentModel(data: data)

      $0 = model
      return model
    }
  }

  @Test func testCoordinates() async throws {
    let model = try loadTestModel()
    #expect(model.coordinates.count == 4060, "GPS coordinates mismatch")
  }

  @Test func testSplits() async throws {
    let model = try loadTestModel()
    let splits = model.splits

    // All splits except the last one should be whole
    #expect(splits.dropLast(1).allSatisfy({ $0.distance.isWhole }))

    // The last split should be partial
    switch splits.last!.distance {
    case .whole(_):
      Issue.record("Last split is not partial")
    case .partial(let p):
      #expect(p > 0.13 && p < 0.14)
    }

    // Verify data manually.
    let expectedPaces = [
      512, 512, 518, 507, 491, 487, 487, 472, 451
    ]
    let expectedHeartRates = [
      151, 150, 148, 151, 152, 156, 161, 158, 180
    ]
    let expectedVert = [41, 13, 2, -31, -20, -21, 22, -19, -5]
    for i in splits.indices {
      #expect(Int(splits[i].paceSecondsPerMile!) == expectedPaces[i])
      #expect(splits[i].avgHeartRate! == expectedHeartRates[i])
      #expect(splits[i].elevationChange! == expectedVert[i])
    }
  }
}

extension Bundle {
  static let tests = Bundle(for: BundleID.self)
}

private class BundleID {}
