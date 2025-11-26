// Copyright © 2025 Raj Ramamurthy.

import CoreLocation
import MapKit
import SwiftUI

struct RouteMapView: View {
  var coordinates: [CLLocationCoordinate2D]

  var body: some View {
    Map {
      MapPolyline(coordinates: coordinates)
        .stroke(.blue, lineWidth: 3)
    }
  }
}
