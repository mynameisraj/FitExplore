// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

struct ContentView: View {
  @Binding var document: FitExploreDocument

  var body: some View {
    HeartRateChart(document: document)
//    NavigationSplitView {
//      VStack {
//        SplitsTable(document: document)
//        HeartRateChart(document: document)
//      }
//    } detail: {
//      VStack {
//        RouteMap(coordinates: document.coordinates)
//        RouteTimeline(document: $document)
//      }
//    }
  }
}
