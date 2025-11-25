//
//  FitExploreDocument.swift
//  FitExplore
//
//  Created by Raj Ramamurthy on 11/24/25.
//

import SwiftUI
import UniformTypeIdentifiers

nonisolated struct FitExploreDocument: FileDocument {
  var text: String
  
  init(text: String = "Hello, world!") {
    self.text = text
  }
  
  static let readableContentTypes: [UTType] = [.fitFile]
  
  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents,
          let string = String(data: data, encoding: .utf8)
    else {
      throw CocoaError(.fileReadCorruptFile)
    }
    text = string
  }
  
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let data = text.data(using: .utf8)!
    return .init(regularFileWithContents: data)
  }
}

extension UTType {
  nonisolated static let fitFile = UTType(importedAs: "com.rajramamurthy.fit")
}
