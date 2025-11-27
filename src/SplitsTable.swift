// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

struct SplitsTable: View {
  var document: FitExploreDocument
  @State private var sortOrder = [KeyPathComparator(\Split.distance)]

  var body: some View {
    Table(document.splits.sorted(using: sortOrder), sortOrder: $sortOrder) {
      TableColumn("mi", value: \.distance) { split in
        Text(split.distanceString)
      }
      .width(40)

      TableColumn("Pace") { split in
        Text(formatPace(split.paceSecondsPerMile))
      }
      .width(35)

      TableColumn("Avg HR") { split in
        // Force Text overload - use explicit return
        if let hr = split.avgHeartRate {
          return Text("\(hr) bpm")
        } else {
          return Text("-:--").foregroundStyle(.secondary)
        }
      }
      .width(55)

      TableColumn("Δ Elev.") { split in
        // Force Text overload - use explicit return
        if let elev = split.elevationChange {
          return Text("\(elev > 0 ? "+" : "")\(elev)")
            .foregroundStyle(
              elev > 0 ? .green : (elev < 0 ? .red : .primary))
        } else {
          return Text("--").foregroundStyle(.secondary)
        }
      }
      .width(40)
    }
    .frame(width: 240)
  }

  private func formatPace(_ secondsPerMile: Double?) -> String {
    guard let seconds = secondsPerMile else { return "--:--" }
    return Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond))
  }
}
