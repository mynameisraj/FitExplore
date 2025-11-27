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
    splitNumber: Int, records: borrowing [RecordMesg],
    startIndex: Int, endIndex: Int, startAltitude: Double?, stoppedTime: UInt32
  ) {
    self.init(
      splitNumber: splitNumber, distance: .whole(splitNumber),
      records: records, startIndex: startIndex, endIndex: endIndex,
      startAltitude: startAltitude, stoppedTime: stoppedTime)
  }

  init(
    splitNumber: Int, partialDistance: Double,
    records: borrowing [RecordMesg], startIndex: Int, endIndex: Int,
    startAltitude: Double?, stoppedTime: UInt32
  ) {
    self.init(
      splitNumber: splitNumber, distance: .partial(partialDistance),
      records: records, startIndex: startIndex, endIndex: endIndex,
      startAltitude: startAltitude, stoppedTime: stoppedTime)
  }

  fileprivate init(
    splitNumber: Int, distance: Distance, records: borrowing [RecordMesg],
    startIndex: Int, endIndex: Int, startAltitude: Double?,
    stoppedTime: UInt32
  ) {
    let splitRecords = records[startIndex..<endIndex]

    let pace = Self.pace(records: splitRecords, stoppedTime: stoppedTime)
    let avgHR = Self.averageHeartRate(records: splitRecords)
    let elevationChange = Self.elevationChange(
      records: splitRecords, startAltitude: startAltitude)

    self.init(
      id: splitNumber, distance: distance, paceSecondsPerMile: pace,
      avgHeartRate: avgHR, elevationChange: elevationChange)
  }

  private static func pace(
    records: borrowing some BidirectionalCollection<RecordMesg>,
    stoppedTime: UInt32
  ) -> Double? {
    guard let startTime = records.first?.getTimestamp(),
      let endTime = records.last?.getTimestamp(),
      let startDist = records.first?.getDistance(),
      let endDist = records.last?.getDistance()
    else { return nil }

    let totalElapsedSeconds = endTime.timestamp - startTime.timestamp
    // Subtract stopped time to get actual moving time
    let movingSeconds = totalElapsedSeconds - stoppedTime

    let distanceMeters = endDist - startDist
    let distanceMiles = distanceMeters / Constants.metersPerMile

    return distanceMiles <= 0 ? nil : Double(movingSeconds) / distanceMiles
  }

  private static func averageHeartRate(
    records: borrowing some BidirectionalCollection<RecordMesg>
  ) -> Int? {
    let heartRates = records.compactMap { $0.getHeartRate() }
    guard !heartRates.isEmpty else { return nil }

    let sum = heartRates.reduce(0) { $0 + Int($1) }
    return sum / heartRates.count
  }

  private static func elevationChange(
    records: borrowing some BidirectionalCollection<RecordMesg>,
    startAltitude: Double?
  ) -> Int? {
    guard let startAltitude, let end = records.last else { return nil }
    guard let endAltitude = end.getAltitude() ?? end.getEnhancedAltitude()
    else { return nil }

    let changeMeters = endAltitude - startAltitude
    let changeFeet = changeMeters * Constants.feetPerMeter

    return Int(changeFeet.rounded())
  }
}
