// Copyright © 2025 Raj Ramamurthy.

import FITSwiftSDK
import Foundation

/// Represents a single split (1-mile segment) of a workout.
struct Split: Identifiable {
  enum Distance: Equatable, Comparable {
    case whole(Int)
    case partial(Double)

    var isWhole: Bool {
      switch self {
      case .whole: return true
      case .partial: return false
      }
    }
  }

  var id: Int
  var distance: Distance
  var paceSecondsPerMile: Double?
  var avgHeartRate: Int?
  var elevationChange: Int?

  var distanceString: String {
    switch distance {
    case .partial(let d):
      d.formatted(.number.precision(.significantDigits(..<3)))
    case .whole(let w):
      String(w)
    }
  }
}

// MARK: - FIT Conversions

extension Split {
  init(
    splitNumber: Int, records: [RecordMesg], startIndex: Int, endIndex: Int,
    startAltitude: Double?
  ) {
    self.init(splitNumber: splitNumber, distance: .whole(splitNumber),
      records: records, startIndex: startIndex, endIndex: endIndex,
      startAltitude: startAltitude)
  }

  init(
    splitNumber: Int, partialDistance: Double,
    records: [RecordMesg], startIndex: Int, endIndex: Int,
    startAltitude: Double?
  ) {
    self.init(splitNumber: splitNumber, distance: .partial(partialDistance),
      records: records, startIndex: startIndex, endIndex: endIndex,
      startAltitude: startAltitude)
  }

  fileprivate init(
    splitNumber: Int, distance: Distance, records: [RecordMesg],
    startIndex: Int, endIndex: Int, startAltitude: Double?
  ) {
    // FIXME: check this. Should it ignore end index?
    let splitRecords = Array(records[startIndex...endIndex])

    let pace = Self.pace(records: splitRecords)
    let avgHR = Self.averageHeartRate(records: splitRecords)
    let elevationChange = Self.elevationChange(
      records: splitRecords, startAltitude: startAltitude)

    self.init(
      id: splitNumber, distance: distance, paceSecondsPerMile: pace,
      avgHeartRate: avgHR, elevationChange: elevationChange)
  }

  private static func pace(records: [RecordMesg]) -> Double? {
    guard let startTime = records.first?.getTimestamp(),
      let endTime = records.last?.getTimestamp(),
      let startDist = records.first?.getDistance(),
      let endDist = records.last?.getDistance()
    else { return nil }

    let elapsedSeconds = endTime.timestamp - startTime.timestamp
    let distanceMeters = endDist - startDist
    let distanceMiles = distanceMeters / Constants.metersPerMile
    return distanceMiles <= 0 ? nil : Double(elapsedSeconds) / distanceMiles
  }

  private static func averageHeartRate(records: [RecordMesg]) -> Int? {
    let heartRates = records.compactMap { $0.getHeartRate() }
    guard !heartRates.isEmpty else { return nil }

    let sum = heartRates.reduce(0) { $0 + Int($1) }
    return sum / heartRates.count
  }

  private static func elevationChange(
    records: [RecordMesg], startAltitude: Double?
  ) -> Int? {
    guard let start = startAltitude else { return nil }
    guard let end =
      records.last?.getAltitude() ?? records.last?.getEnhancedAltitude()
    else {
      return nil
    }

    let changeMeters = end - start
    let changeFeet = changeMeters * Constants.feetPerMeter

    return Int(changeFeet.rounded())
  }
}
