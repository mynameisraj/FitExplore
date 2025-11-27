// Copyright © 2025 Raj Ramamurthy.

import Charts
import SwiftUI

struct HeartRateChart: View {
  enum XAxisMode {
    case time
    case distance
  }

  var document: FitExploreDocument
  private var data: [HeartRateDataPoint] { document.heartRateData }
  @State private var xAxisMode: XAxisMode = .distance

  var body: some View {
    VStack {
      // Mode toggle
      Picker("X-Axis", selection: $xAxisMode) {
        Text("Time").tag(XAxisMode.time)
        Text("Distance").tag(XAxisMode.distance)
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 200)
      .padding()

      // Chart
      Chart(data) { point in
        LineMark(
          x: .value(
            xAxisMode == .time ? "Time" : "Distance",
            xAxisMode == .time
              ? Double(point.timestamp) : point.distance
          ),
          y: .value("Heart Rate", point.heartRate)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(point.isStopped ? .gray : .red)
      }
      .chartXAxis {
        AxisMarks(
          values: xAxisMode == .time
            ? .stride(by: 600)  // 10 minutes in seconds
            : .stride(by: Constants.metersPerMile)
        ) { value in
          AxisGridLine()
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
