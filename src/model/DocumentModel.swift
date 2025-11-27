// Copyright © 2025 Raj Ramamurthy.

import CoreLocation
import FITSwiftSDK

/// Data model class representing all operations that happen on the FIT file.
@Observable
final class DocumentModel {
  private let fitListener: FitListener
  private var _coordinates: [CLLocationCoordinate2D]?
  private var _splits: [Split]?
  private var _stoppedTimeRanges: [Range<UInt32>]?

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

  private var stoppedTimeRanges: [Range<UInt32>] {
    if _stoppedTimeRanges == nil {
      _stoppedTimeRanges = makeStoppedTimeRanges()
    }
    return _stoppedTimeRanges!
  }

  var splits: [Split] {
    if _splits == nil {
      _splits = makeSplits()
    }
    return _splits!
  }

  private func makeSplits() -> [Split] {
    let records = fitListener.fitMessages.recordMesgs
    guard !records.isEmpty else { return [] }

    let stoppedRanges = self.stoppedTimeRanges

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
        let stoppedTime = calculateStoppedTime(
          records: records, startIndex: splitStartIndex, endIndex: index,
          stoppedRanges: stoppedRanges)
        let split = Split(
          splitNumber: currentMile, records: records,
          startIndex: splitStartIndex, endIndex: index,
          startAltitude: splitStartAltitude, stoppedTime: stoppedTime)
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
    if splitStartIndex < records.endIndex,
      let endDistance = records.last?.getDistance(), let lastSplitEnd
    {
      let partialDistance =
        (endDistance - lastSplitEnd) / Constants.metersPerMile
      let stoppedTime = calculateStoppedTime(
        records: records, startIndex: splitStartIndex,
        endIndex: records.endIndex, stoppedRanges: stoppedRanges)

      let split = Split(
        splitNumber: currentMile, partialDistance: partialDistance,
        records: records, startIndex: splitStartIndex,
        endIndex: records.endIndex, startAltitude: splitStartAltitude,
        stoppedTime: stoppedTime)
      splits.append(split)
    }

    return splits
  }

  /// Builds time ranges when the timer was stopped (paused).
  private func makeStoppedTimeRanges() -> [Range<UInt32>] {
    let events = fitListener.fitMessages.eventMesgs
    var ranges: [Range<UInt32>] = []

    // Assume the workout begins stopped.
    var lastStopTime: UInt32? =
      events.lazy.compactMap({ $0.getTimestamp() }).first?.timestamp

    for event in events {
      guard event.getEvent() == .timer,
        let timestamp = event.getTimestamp(),
        let eventType = event.getEventType()
      else {
        continue
      }

      if eventType == .stop || eventType == .stopAll {
        lastStopTime = timestamp.timestamp
      } else if eventType == .start, let stop = lastStopTime {
        // Start preceded by a stop, record the range of stopped time.
        let r = stop..<timestamp.timestamp
        if !r.isEmpty { ranges.append(r) }
        lastStopTime = nil
      }
    }

    return ranges
  }

  /// Calculates total stopped time (in seconds) within a split's time range.
  private func calculateStoppedTime(
    records: borrowing [RecordMesg], startIndex: Int, endIndex: Int,
    stoppedRanges: [Range<UInt32>]
  ) -> UInt32 {
    guard !stoppedRanges.isEmpty else { return 0 }
    // Calculate time in the split that was spent stopped.
    let times = records[startIndex..<endIndex].lazy.compactMap({
      $0.getTimestamp()
    })
    guard let startTime = times.first?.timestamp,
      let endTime = times.last?.timestamp
    else {
      assertionFailure("Missing timestamps?")
      return 0
    }

    var stoppedTime: UInt32 = 0
    for range in stoppedRanges {
      // Calculate overlap between stopped range and split range
      let overlapStart = max(range.lowerBound, startTime)
      let overlapEnd = min(range.upperBound, endTime)
      if overlapStart < overlapEnd {
        stoppedTime += (overlapEnd - overlapStart)
      }
    }
    return stoppedTime
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
