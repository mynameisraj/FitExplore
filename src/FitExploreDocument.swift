// Copyright © 2025 Raj Ramamurthy.

import FITSwiftSDK
import SwiftUI
import Synchronization
import UniformTypeIdentifiers

struct FitExploreDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.fitFile]

  @UncheckedSendable var fitListener: FitListener

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    let stream = FITSwiftSDK.InputStream(data: data)
    let decoder = Decoder(stream: stream)
    let listener = FitListener()
    decoder.addMesgListener(listener)
    try decoder.read()

    self.fitListener = listener
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    fatalError("Unsupported")
  }
}

extension UTType {
  nonisolated static let fitFile = UTType(importedAs: "com.garmin.fit")
}
