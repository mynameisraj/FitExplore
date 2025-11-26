# FIT Explorer

This is a project to build a macOS app using SwiftUI that reads Garmin FIT
files.


## Goals

It has several goals:

- Provide a high level overview, using charts/tables, of individual workouts.
- Serve as a guide for running (but expanded later on to cycling) analysis to
  make decisions about future training adjustments.

## Current Features

Implemented:
- **Map view**: Displays the workout route as a blue polyline using SwiftUI's
  Map and MapPolyline. The map automatically extracts GPS coordinates from FIT
  file RecordMesg data, converting from semicircles to degrees.

Planned:
- Show data in the FIT file in various time-series charts.
- Support drilling in to windows of the time series, e.g. selecting a single
  minute or split. (Charts support changing x axis to distance or time)
- Give tables / stats on basics: time in heart rate zones, individual splits,
  pacing.
- Show the run on a map that corresponds with the selection in the charts, and
  includes coloring along the path for various metrics (pace, heart rate,
  cadence, etc)
- Compare efforts against each other using some sort of similarity index. Each
  effort/run is a separate file.
- Export charts about a workout to images to share with others.

## Architecture

- **FitExploreDocument**: SwiftUI FileDocument that reads .fit files and
  provides access to the DocumentModel.
- **DocumentModel**: @Observable class that encapsulates all FIT file
  operations. Uses FITSwiftSDK's FitListener to parse the file and provides
  computed properties (like `coordinates`) for accessing processed data. Caches
  expensive computations where appropriate.
- **Views**: Pure SwiftUI views (ContentView, RouteMapView) that operate on
  data from the document without directly importing FITSwiftSDK.

Important details:
- The app is read only. It opens the files, but does not write to them. It does
  not maintain its own database. It is purely a lens onto existing data.
- The app may gain an iOS counterpart in the future that directly integrates
  with HealthKit, so it may require its own intermediate data structures.
- Currently it is only used for running, but may be expanded to cycling.

## Workflow

The current workflow is:

1. Go on a run with an Apple Watch, using the Apple Workout app.
2. Export that run to a FIT file on iPhone, using the HealthFit app for iOS.
3. This app reads the FIT file exported in step 2.

## File Structure

- **src/FitExploreApp.swift**: Main app entry point
- **src/FitExploreDocument.swift**: FileDocument implementation for .fit files
- **src/DocumentModel.swift**: @Observable model class that encapsulates FIT
  file parsing and data access. Only file that imports FITSwiftSDK.
- **src/ContentView.swift**: Main content view
- **src/MapView.swift**: RouteMapView component for displaying workout routes
- **src/UncheckedSendable.swift**: Utility for thread-safe property wrappers

## Guidelines for Programming

- All lines must wrap to 80c, with 2 space indent. Use the Google Swift style
  guide as inspiration for Swift style.
- Avoid all use of `Binding(get:set:)` and use computed properties instead.
- Absolutely no `ObservableObject` usage. Everything must be done with
  `@Observable`.
- Use SwiftUI's `Table` and Swift Charts. Avoid using AppKit or UIKit controls.
- The Garmin FITSwiftSDK interface is a dependency, so the app should not need
  to implement its own FIT processing code (other than special metrics).
  https://github.com/garmin/fit-swift-sdk.git - this is available in the
  DerivedData folder, e.g.
  /Users/raj/Library/Developer/Xcode/DerivedData/FitExplore-actngjpipgbuqxcnadavzbgobums/SourcePackages/checkouts/fit-swift-sdk
- The app is primarily targeted at exploring raw data, so it should support
  generating charts from arbitrary time series, as well as viewing all the raw
  data and copying it easily from a table format.
- Views should not import FITSwiftSDK directly. Only DocumentModel imports it.
  Views access FIT data through DocumentModel's computed properties.
