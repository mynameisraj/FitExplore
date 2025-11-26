// Copyright © 2025 Raj Ramamurthy.

import CoreLocation
import FITSwiftSDK

/// Data model class representing all operations that happen on the FIT file.
@Observable
final class DocumentModel {
  private let fitListener: FitListener
  private var _coordinates: [CLLocationCoordinate2D]?

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
