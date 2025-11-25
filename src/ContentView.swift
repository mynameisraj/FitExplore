//
//  ContentView.swift
//  FitExplore
//
//  Created by Raj Ramamurthy on 11/24/25.
//

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
