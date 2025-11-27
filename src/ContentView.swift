// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

struct ContentView: View {
  @Binding var document: FitExploreDocument

  var body: some View {
    NavigationSplitView {
      SplitsTable(document: document)
    } detail: {
      VStack {
        RouteMap(coordinates: document.coordinates)
        RouteTimeline(document: $document)
      }
    }
  }
}
