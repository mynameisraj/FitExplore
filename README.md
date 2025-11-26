# FIT Explorer

This is a project to build a macOS app using SwiftUI that reads Garmin FIT
files.


## Goals

It has several goals:

- Provide a high level overview, using charts/tables, of individual workouts.
- Serve as a guide for running (but expanded later on to cycling) analysis to
  make decisions about future training adjustments.

## Features

The ideal feature set includes:

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

There are a few important details for now:

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

## Guidelines for Programming

- All lines must wrap to 80c, with 2 space indent. Use the Google Swift style
- The Garmin FITSwiftSDK interface is a dependency, so the app should not need
  to implement its own FIT processing code (other than special metrics).
