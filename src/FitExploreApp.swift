// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

@main
struct FitExploreApp: App {
  var body: some Scene {
    DocumentGroup(newDocument: FitExploreDocument()) { file in
      ContentView(document: file.$document)
    }
  }
}
