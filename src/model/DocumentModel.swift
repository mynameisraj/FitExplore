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

  // FIXME: there's a significant bug here. If we paused, we count that against
  // the split distance. The split should only include moving time.
  private func makeSplits() -> [Split] {
    let records = fitListener.fitMessages.recordMesgs
    guard !records.isEmpty else { return [] }

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
