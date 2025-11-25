//
//  FitExploreApp.swift
//  FitExplore
//
//  Created by Raj Ramamurthy on 11/24/25.
//

import SwiftUI

@main
struct FitExploreApp: App {
  var body: some Scene {
    DocumentGroup(newDocument: FitExploreDocument()) { file in
      ContentView(document: file.$document)
    }
  }
}
