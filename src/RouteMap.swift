// Copyright © 2025 Raj Ramamurthy.

import CoreLocation
import MapKit
import SwiftUI

struct RouteMap: View {
  var coordinates: [CLLocationCoordinate2D]

  var body: some View {
    // TODO: implement dynamic stroke coloring based on data.
    Map {
      MapPolyline(coordinates: coordinates)
        .stroke(.blue, lineWidth: 3)
    }
  }
}
