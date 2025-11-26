// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

@main
struct FitExploreApp: App {
  var body: some Scene {
    DocumentGroup(viewing: FitExploreDocument.self) { file in
      ContentView(document: file.$document)
    }
  }
}
