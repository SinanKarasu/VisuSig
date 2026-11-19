# DAW direction and current baseline

VisuSig is growing toward a graph-based DAW for generative music experimentation.
The Audio Units and MIDI panels remain available alongside the DAW panel.

## Intended graph

A single session graph should support multiple instances of each source type:

- audio files;
- microphones and supported audio device inputs;
- MIDI keyboards and supported MIDI endpoints;
- MIDI files;
- generators producing notes, rhythms, chords, or evolving patterns.

MIDI events route through MIDI processing and software instruments. Instrument
audio outputs and direct audio sources route through audio processing into mixer
channels. The mixer sits at the bottom of the graph and feeds audio output.
Connections need to distinguish audio signals from MIDI events.

The eventual session graph should own routing and running state. Panels should
provide views and controls over that session, preserving playback, instrument
state, and routing when switching panels.

The user has identified generative music experimentation as the direction.
A shared clock, repeatable random seeds, MIDI transformations, and performance
capture have been discussed as possibilities. Their behavior and implementation
order are still open.

## Implemented baseline

Baseline commit 011e3f3 adds the MIDI session and DAW layout.

| Area | Current behavior |
| --- | --- |
| Audio Units | Existing audio graph and plug-in host workspace |
| MIDI | One selected instrument, one audio file player, one selected external MIDI source, and a virtual MIDI destination |
| Instrument switching | Stops the running MIDI session, selects the instrument, and starts a new session |
| MIDI source switching | Updates the external input connection and releases held notes |
| Panel switching | Retains visited workspace views and their in-memory state |
| DAW | Add, rename, and remove multiple source cards with drawn paths to an instrument stage where applicable, a mixer, and output |

The DAW cards and paths currently describe a layout. Device selection, file
loading, instrument assignment, editable connections, mixer processing, and
playback for those cards still need engine integration. The MIDI panel and Audio
Units panel currently have their own runtime ownership. A unified DAW session
has yet to be implemented.

Layout retention currently lasts within the open workspace/window lifecycle.
Project save/load and restoration across app launches have yet to be implemented.

## Existing model boundaries

Durable node descriptors and graph connections belong in the serializable model.
Live Audio Units, audio engines, file handles, and MIDI connections belong in
runtime adapters keyed by stable identity.

Reuse the shared VisualMesh model and the existing payload/runtime boundary.
See ../README.md and HIERARCHY.md for the established architecture.

## Roland Cloud and platforms

The current Xcode target is macOS. App Sandbox is disabled in
VisuSig/VisuSig.entitlements.

During diagnosis, a small host signed with VisuSig's entitlements failed to
instantiate SRX DANCE TRAX and JUNO-106 with NSOSStatusErrorDomain -3000
(invalidComponentID). Removing only App Sandbox allowed both instruments to
instantiate and the audio engine to start. AUMIDISynth worked with sandboxing.
SRX DANCE TRAX also passed Apple's Audio Unit validator.

Explicit out-of-process loading in the sandboxed diagnostic host stalled.
That path remains unresolved. Successful tests in the diagnostic host do not
establish interactive behavior in VisuSig.

A visionOS port will need platform-specific runtime and interface work,
including adaptation of AppKit plug-in editor integration. Desktop Roland AUv2
binaries require compatible replacements on other platforms.

As checked on November 19, 2026, Roland documents ZENOLOGY GX for iPad AUv3
support from version 1.9.3, with account authorization inside the app. Its App
Store compatibility lists iPad. Vision Pro support has not been verified.
Recheck these external product details before depending on them.

- [Roland iPad AUv3 support](https://support.roland.com/hc/en-us/articles/50742562732827-ZENOLOGY-GX-for-iPad-Can-I-use-it-as-an-AUv3-plugin-in-a-DAW)
- [Roland account and Cloud Manager requirements](https://support.roland.com/hc/en-us/articles/50741522469147-ZENOLOGY-GX-for-iPad-Do-I-need-a-Roland-Account-and-Roland-Cloud-Manager-to-use-ZENOLOGY-GX)
- [ZENOLOGY GX App Store compatibility](https://apps.apple.com/us/app/zenology-gx-synthesizer/id6756631713)

## Verification status and open decisions

The baseline macOS Debug build passed. After disabling App Sandbox, Debug and
Release builds passed and their signed entitlements were inspected.

Live MIDI hardware switching, interactive panel retention, and Roland plug-in
loading through the rebuilt VisuSig interface still need verification.

The following need design decisions as implementation proceeds:

- How the existing panels share ownership of the eventual DAW session.
- How sources, instruments, effects, ports, and connections are represented.
- How graph edits are applied safely to a running engine.
- How timing, MIDI scheduling, and audio transport are coordinated.
- How projects preserve routing, file references, plug-in identity, and state.
- Which generators and transformations form the first playable experiment.
