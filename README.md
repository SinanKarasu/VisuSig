# VisuSig

An experiment in building a DAW (Digital Audio Workstation) using a **visual node graph** as its core paradigm.

Instead of a traditional linear timeline, VisuSig lets you construct an audio processing chain by dropping Audio Unit (AU) plugins onto a canvas and connecting their ports with bezier wires. The visual graph *is* the audio graph — wiring two nodes together instantly routes audio through them in `AVAudioEngine`.

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **AU Plugin Browser** — lists all installed Audio Unit effects on the system
- **Node Canvas** — drag AU plugins onto the canvas; they appear as colour-coded nodes (blue = source, purple = effect, green = output)
- **Bezier Wiring** — drag from an output port to an input port to route audio; delete a wire to break the connection
- **Live Audio Routing** — `AVAudioEngine` is rebuilt automatically whenever the graph changes
- **Native Plugin GUIs** — right-click any effect node → *Open Plugin UI* to open the AU's own interface in a floating, non-modal window
- **Audio File Loading** — load any `.aif`, `.wav`, `.mp3`, `.m4a`, or `.caf` file into the Source node; loops continuously while playing

## Architecture

The central insight is that `AudioGraph` subclasses `Mesh` (the visual graph model), overriding `connect`, `removeEdge`, and `deleteNodes` to rebuild the `AVAudioEngine` chain whenever the user changes the wiring. There is no separate "audio model" — the canvas *is* the audio routing table.

```
AudioGraph (AVAudioEngine host)
  └── Mesh (visual node/edge model)
        ├── NodeBase  (canvas node + NodeRole: source | effect | output)
        ├── PortBase  (typed port: input | output)
        └── EdgeBase  (visual wire → AVAudioEngine connection)
```

## Requirements

- macOS 15 Sequoia or later
- Xcode 15 or later
- Apple Silicon or Intel Mac

## Getting Started

1. Clone the repo
2. Open `VisuSig.xcodeproj` in Xcode
3. Select the *VisuSig* scheme and run on *My Mac*
4. Click **Load Audio...** and choose an audio file
5. Drop an AU effect from the browser on the left onto the canvas
6. Wire: **Source Out → Effect In → Effect Out → Output In**
7. Hit Play

## Roadmap

- [ ] iPadOS port (touch-first wiring, AUv3 support)
- [ ] visionOS port (spatial node canvas)
- [ ] Instrument nodes (MIDI input → AU instrument → effects chain)
- [ ] Save / restore graph state
- [ ] Multiple audio sources and parallel chains
- [ ] Parameter automation via node handles

## License

MIT — see [LICENSE](LICENSE).
