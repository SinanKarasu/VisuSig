# VisuSig project guidance

## Project and architecture

VisuSig is a SwiftUI visual workbench with Payload, Hierarchy, Audio Units,
MIDI, and DAW workspaces. Preserve these workspaces when extending the DAW.

Read README.md and Docs/HIERARCHY.md for the existing payload and hierarchy
boundaries. Read Docs/DAW.md before changing audio/MIDI routing or DAW behavior.

- Keep durable, serializable graph content separate from live audio runtime objects.
- Reuse the shared VisualMesh package (https://github.com/SinanKarasu/VisualMesh, tracked on `main`).
  Do not add graph models or graph editors to this app; extend the package.
  Its products: `VisualMesh` (UI-free core), `VisualMeshUI` (SwiftUI 2D
  editor), `VisualMeshExamples`. The local clone is
  /Volumes/GitHubDeveloper/Packages/VisualMesh; drag it into the Xcode
  workspace to edit the package in place.
- Keep AVFoundation and Audio Unit runtime dependencies in the audio adapter.
- Preserve reusable definitions, instance identities, typed ports, and boundary mappings.
- The intended DAW supports multiple audio and MIDI sources feeding a mixer.
  Generative music experimentation is part of that direction.

## Current implementation

- MasterMenuView retains visited workspaces so switching panels preserves their state.
- MIDIWorkspace owns a MIDI/audio session with an instrument, an audio file player,
  a mixer, a virtual MIDI destination, and a selectable external MIDI source.
- Instruments can be switched while running by stopping and restarting the session.
- External MIDI sources can be switched while running through the existing connection.
- DAWWorkspace currently edits an in-memory routing layout. Its drawn connections
  have no audio/MIDI engine implementation.
- App Sandbox is currently disabled for the macOS target because sandboxed
  instantiation of tested Roland Cloud AUv2 instruments returned OSStatus -3000.
- visionOS is a future port. Confirm platform and plug-in compatibility before
  treating a macOS capability as available there.

## Build and verification

Run from the repository root. Xcode is required; it fetches VisualMesh from GitHub.

Build the macOS Debug app:

```sh
xcodebuild -project VisuSig.xcodeproj -scheme VisuSig \
  -configuration Debug -destination 'platform=macOS' build
```

For compilation checks that do not need a signed app, append CODE_SIGNING_ALLOWED=NO.
Use a signed build when verifying entitlements or plug-in loading.

Run existing payload checks when changing payload behavior:

```sh
xcrun swiftc VisuSig/Payload/Payload.swift \
  VisuSig/Payload/AtlasStatementPayload.swift Tests/PayloadModelChecks.swift \
  -o /tmp/VisuSigPayloadChecks
/tmp/VisuSigPayloadChecks
```

Run shared package tests when changing VisualMesh:

```sh
swift test --package-path /Volumes/GitHubDeveloper/Packages/VisualMesh
```

- Run checks appropriate to the change and report their results.
- Distinguish successful compilation from interactive verification, audible
  playback, MIDI hardware checks, and native plug-in interface checks.
- Check session cleanup, held-note release, source changes, instrument changes,
  and state across panel switches when modifying MIDI lifecycle behavior.
- Serialize Xcode builds sharing a DerivedData directory to avoid build database locks.

## Collaboration and handoffs

- Inspect git status and relevant diffs before editing. Preserve other contributors' work.
- For simultaneous implementation, use separate branches and Git worktrees.
- Coordinate changes to project.pbxproj and other shared integration files.
- When assigned review, report findings and follow the user's requested editing scope.
- Handoffs should identify the objective, branch or commit, changed behavior,
  verification performed, remaining limitations, and next step.
- Keep shared project instructions here. CLAUDE.md imports this file.
- Record durable DAW decisions in Docs/DAW.md, with implemented and planned
  behavior clearly identified. Keep transient task progress in the handoff.
- Make focused changes and keep generated Xcode user preferences out of
  feature commits unless explicitly requested.
