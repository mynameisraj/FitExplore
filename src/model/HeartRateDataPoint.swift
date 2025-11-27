// Copyright © 2025 Raj Ramamurthy.

import Foundation

/// Represents a single heart rate data point for charting.
struct HeartRateDataPoint: Identifiable {
  let id: UUID = UUID()
  let timestamp: UInt32
  let distance: Double  // in meters
  let heartRate: UInt8
  let isStopped: Bool
}
