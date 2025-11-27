// Copyright © 2025 Raj Ramamurthy.

import CoreLocation
import FITSwiftSDK

/// Data model class representing all operations that happen on the FIT file.
@Observable
final class DocumentModel {
  private let fitListener: FitListener
  private var _coordinates: [CLLocationCoordinate2D]?
  private var _splits: [Split]?

  init(data: Data) throws {
    let stream = FITSwiftSDK.InputStream(data: data)
    let decoder = Decoder(stream: stream)
    let listener = FitListener()
    decoder.addMesgListener(listener)
    try decoder.read()
    self.fitListener = listener
  }

  var coordinates: [CLLocationCoordinate2D] {
    if _coordinates == nil {
      // FIXME: async?
      _coordinates = fitListener.fitMessages.recordMesgs.compactMap { rm in
        guard let lat = rm.getPositionLat(), let long = rm.getPositionLong()
        else { return nil }

        return CLLocationCoordinate2D(
          latitude: lat.asDegreesFromSemicircles,
          longitude: long.asDegreesFromSemicircles)
      }
    }
    return _coordinates!
  }

  var splits: [Split] {
    if _splits == nil {
      _splits = makeSplits()
    }
    return _splits!
  }

  private func makeSplits() -> [Split] {
    let allRecords = fitListener.fitMessages.recordMesgs
    guard !allRecords.isEmpty else { return [] }

    // Filter out records when timer was stopped
    let records = filterActiveRecords(allRecords)

    var splits: [Split] = []
    var currentMile = 1
    var splitStartIndex = 0 // index into records
    var splitStartAltitude: Double?
    var lastSplitEnd: Float64? // end of prior full mile

    for (index, record) in records.enumerated() {
      guard let distance = record.getDistance() else { continue }

      let targetDistance = Double(currentMile) * Constants.metersPerMile

      // Check if we've crossed a mile boundary.
      if distance >= targetDistance {
        // Compute split statistics.
        let split = Split(
          splitNumber: currentMile, records: records,
          startIndex: splitStartIndex, endIndex: index,
          startAltitude: splitStartAltitude)
        splits.append(split)

        // Prepare for next split.
        lastSplitEnd = targetDistance
        currentMile &+= 1
        splitStartIndex = index
        splitStartAltitude =
          record.getAltitude() ?? record.getEnhancedAltitude()
      }

      // Track initial altitude.
      if splitStartAltitude == nil {
        splitStartAltitude =
          record.getAltitude() ?? record.getEnhancedAltitude()
      }
    }

    // Handle partial final split.
    if splitStartIndex < records.count - 1,
      let endDistance = records.last?.getDistance(), let lastSplitEnd
    {
      let partialDistance =
        (endDistance - lastSplitEnd) / Constants.metersPerMile
      let split = Split(
        splitNumber: currentMile, partialDistance: partialDistance,
        records: records, startIndex: splitStartIndex,
        endIndex: records.count - 1, startAltitude: splitStartAltitude)
      splits.append(split)
    }

    return splits
  }

  /// Builds time ranges when the timer was active (not stopped).
  private func buildActiveTimeRanges() -> [(start: UInt32, end: UInt32)] {
    let events = fitListener.fitMessages.eventMesgs
    var ranges: [(start: UInt32, end: UInt32)] = []
    var currentStart: UInt32?

    for event in events {
      guard event.getEvent() == .timer,
        let timestamp = event.getTimestamp(),
        let eventType = event.getEventType()
      else {
        continue
      }

      if eventType == .start {
        currentStart = timestamp.timestamp
      } else if eventType == .stop, let start = currentStart {
        ranges.append((start: start, end: timestamp.timestamp))
        currentStart = nil
      }
    }

    // If timer still running at end, add final range
    if let start = currentStart,
      let lastRecord = fitListener.fitMessages.recordMesgs.last,
      let lastTimestamp = lastRecord.getTimestamp()
    {
      ranges.append((start: start, end: lastTimestamp.timestamp))
    }

    return ranges
  }

  /// Filters records to only include those when timer was active.
  private func filterActiveRecords(_ records: [RecordMesg]) -> [RecordMesg] {
    let activeRanges = buildActiveTimeRanges()

    // If no timer events found, assume all records are active
    guard !activeRanges.isEmpty else { return records }

    return records.filter { record in
      guard let timestamp = record.getTimestamp() else { return false }
      return activeRanges.contains { range in
        timestamp.timestamp >= range.start && timestamp.timestamp <= range.end
      }
    }
  }
}

extension Int32 {
  /// Assuming `self` represents semicircles, returns a value as degrees,
  /// suitable for use with latitude or longitude.
  @inline(__always)
  fileprivate var asDegreesFromSemicircles: Double {
    // d = s * (180 / 2^31)
    Double(self) * (180.0 / Double(Int32.max))
  }
}
