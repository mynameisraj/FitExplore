// Copyright © 2025 Raj Ramamurthy.

import Charts
import SwiftUI

struct HeartRateChart: View {
  enum XAxisMode {
    case time
    case distance
  }

  var document: FitExploreDocument
  @State private var xAxisMode: XAxisMode = .distance

  var body: some View {
    VStack {
      // Chart title
      Text("Heart rate")
        .font(.headline)
        .padding(.top)

      // Mode toggle
      Picker("X-Axis", selection: $xAxisMode) {
        Text("Time").tag(XAxisMode.time)
        Text("Distance").tag(XAxisMode.distance)
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 200)
      .padding(.bottom)

      // Chart
      Chart {
        // Grey shading for gaps between runs (stopped periods)
        let runs = document.heartRateData
        ForEach(0..<runs.count-1, id: \.self) { index in
          if let endOfRun = runs[index].last,
            let startOfNext = runs[index + 1].first
          {
            let xStart = xAxisMode == .time
              ? Double(endOfRun.timestamp) : endOfRun.distance
            let xEnd = xAxisMode == .time
              ? Double(startOfNext.timestamp) : startOfNext.distance
            RectangleMark(
              xStart: .value("Start", xStart),
              xEnd: .value("End", xEnd),
              yStart: .value("Min", 70),
              yEnd: .value("Max", 200) )
            .foregroundStyle(.gray.opacity(0.2))
          }
        }

        // Heart rate lines
        ForEach(
          document.heartRateData.enumerated(), id: \.offset
        ) { series, run in
          ForEach(run) { point in
            LineMark(
              x: .value(
                xAxisMode == .time ? "Time" : "Distance",
                xAxisMode == .time ? Double(point.timestamp) : point.distance),
              y: .value("Heart Rate", point.heartRate),
              series: .value("Bucket", series))
            .foregroundStyle(.red)
          }
        }
      }
      .chartXAxis {
        AxisMarks(
          values: xAxisMode == .time
            ? .stride(by: 600)  // 10 minutes in seconds
            : .stride(by: Constants.metersPerMile)
        ) { value in
          AxisValueLabel(orientation: .vertical) {
            let value = value.as(Double.self)!
            if xAxisMode == .time {
              Text(formatTime(value))
            } else {
              Text(formatDistance(value))
            }
          }
        }
      }
      .chartYAxis {
        AxisMarks { value in
          AxisGridLine()
          AxisValueLabel {
            if let hr = value.as(UInt8.self) {
              Text("\(hr)")
            }
          }
        }
      }
      .chartYScale(domain: 70...200)
      .chartYAxisLabel("BPM")
      .padding()
    }
  }

  private func formatTime(_ seconds: Double) -> String {
    let minutes = Int(seconds / 60)
    return "\(minutes)m"
  }

  private func formatDistance(_ meters: Double) -> String {
    let miles = meters / Constants.metersPerMile
    return String(format: "%.1f mi", miles)
  }
}
