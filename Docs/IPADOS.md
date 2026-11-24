# iPadOS portability check

## Platforms and workspace

VisuSig now uses one shared app target for macOS 15+ and iPadOS 18+.
The iOS device family is iPad. Mac Catalyst is disabled.

Both VisuSig.xcodeproj and VisuSig.xcworkspace use the shared VisualMesh source
at ../../Packages/VisualMesh. The project has an explicit local package
reference, so opening either entry point uses the same deployment targets.

VisualMesh's local Package.swift explicitly supports iOS 18. Each Swift
package declares its own minimum supported platforms; changing only VisuSig's
iOS deployment target does not update a dependency's platform declaration.
The prior remote revision omitted iOS support, which caused Observation
availability errors even though the app itself targeted iOS 18.

VisualMesh's iPadOS and touch-port support is published in commit 4167fb1 on
its main branch. The app keeps its local package reference for joint source
development. A future remote-only configuration must use that revision or newer.

## Shared functionality

The app compiles its existing Payload, Hierarchy, Audio Units, MIDI, and DAW
workspaces on iPadOS. The music graph, session/package schema, asset collection,
mixer settings, MIDI routing, and plug-in state persistence remain shared.

iPadOS file import uses SwiftUI's fileImporter and security-scoped access.
Project export uses fileExporter with an immutable, Sendable package snapshot.
The package representation is currently prepared in memory, which should be
revisited for large sample libraries and long recordings.

AppKit settings windows and floating plug-in windows have iPad presentations.
The existing settings content is accessible from the gear button in a sheet;
its placeholder controls still need to be backed by real preferences.
Plug-in editors use UIViewControllerRepresentable on iPadOS and
NSViewControllerRepresentable on macOS. The MIDI panel reuses the same host.

On iPadOS, audio engine startup activates AVAudioSession for playback.
Device and buffer preferences, interruptions, and route-change handling need
further development and hardware verification.

## Platform boundaries

- PlatformUI selects system colors and layout constraints.
- WorkspaceSplitView uses a macOS resizable split view and an iPad horizontal layout.
- PlatformImage and PluginViewController select AppKit or UIKit types.
- Plug-in discovery avoids macOS-only icon and custom-view metadata APIs on iPadOS.
- Legacy desktop tools and NSView extensions compile only on macOS.
- The iPad MIDI panel initially selects Apple's Sampler when available.
  Sampler sound-bank setup still needs a user-facing workflow.
- Installed iPad-compatible Audio Units are available to the host. Desktop
  AUv2 binaries and their vendor managers are not installed by this app.

The first iPad pass provides a compilation and startup check. Desktop-sized
grids, narrow multitasking windows, touch wiring, file-provider behavior,
external MIDI devices, and third-party AUv3 interfaces need interactive testing.
The independent MIDI panel and DAW prototype retain the persistence limitations
described in PROJECT_PACKAGE.md.

visionOS is the next platform to address. There is no visionOS app target yet.

## Build commands

```sh
xcodebuild -workspace VisuSig.xcworkspace -scheme VisuSig \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO

xcodebuild -workspace VisuSig.xcworkspace -scheme VisuSig \
  -configuration Debug -destination 'generic/platform=iOS' \
  build CODE_SIGNING_ALLOWED=NO

xcodebuild -workspace VisuSig.xcworkspace -scheme VisuSig \
  -configuration Debug -destination 'platform=macOS,arch=arm64' build

swift test --package-path ../../Packages/VisualMesh
```

Unsigned device builds verify compilation. Running on a physical iPad requires
a development signing identity and provisioning.

## Verification

During this implementation the simulator and unsigned device builds passed,
the macOS build passed, and the shared package's 12 existing tests passed.
The app was installed and launched on an iPad Pro 13-inch simulator, and its
initial Hierarchy workspace was inspected in a screenshot.

The user also confirmed saving a project to iCloud Downloads and reopening it
successfully on a physical iPad. Audible output, hardware MIDI, third-party
AUv3 behavior, and the visionOS port need further verification.


## Touch ports and plug-in fitting

iPad port hit targets now have a minimum 44-point screen diameter independent
of zoom. Overlapping hit areas select the nearest port, with the topmost node
winning exact ties. During a wire drag, the target highlights and the wire
endpoint snaps to its centre.

On iPadOS, a plug-in controller without a preferred content size receives the
available host size. Fixed-size controllers scale down to fit while preserving
their aspect ratio. The same host is used by Audition, the plug-in sheet, and
the MIDI editor, and responds to changes in available space.

Regression tests cover zoomed-out/panned port hits and overlapping targets.
All 7 UI geometry/state tests and 12 core tests passed. An isolated simulator
check exercised Apple's high-pass filter in 300-by-260 and 650-by-140-point
containers. Physical finger accuracy and third-party editor behavior still
need verification on the iPad.
