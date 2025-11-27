// Copyright © 2025 Raj Ramamurthy.

import CoreLocation
import SwiftUI
import UniformTypeIdentifiers

/// Encapsulates a FIT file.
struct FitExploreDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.fitFile]

  private let model: DocumentModel

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    self.model = try .init(data: data)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    fatalError("Unsupported")
  }

  var coordinates: [CLLocationCoordinate2D] { model.coordinates }
  var splits: [Split] { model.splits }
  var heartRateData: [HeartRateDataPoint] { model.heartRateData }
}

extension UTType {
  nonisolated static let fitFile = UTType(importedAs: "com.garmin.fit")
}
