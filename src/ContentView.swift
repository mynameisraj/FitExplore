// Copyright © 2025 Raj Ramamurthy.

import SwiftUI

struct ContentView: View {
  @Binding var document: FitExploreDocument
  
  var body: some View {
    TextEditor(text: $document.text)
  }
}

#Preview {
  ContentView(document: .constant(FitExploreDocument()))
}
