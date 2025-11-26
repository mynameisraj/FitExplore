// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

struct ContentView: View {
  @Binding var document: FitExploreDocument

  var body: some View {
    RouteMapView(coordinates: document.coordinates)
  }
}
