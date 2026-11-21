//
//  AudioGraph.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/11/22.
//

import AudioToolbox
import AVFoundation
import CoreGraphics
import Foundation
import SwiftMIDICore
import SwiftMIDIIO
import VisualMesh
import VisualMeshUI

/// Durable description of a wire. Live telemetry for a wire is kept by
/// `AudioGraph`, keyed by the edge's ID, and never stored in the edge.
struct AudioConnection: Codable, Hashable, Sendable {}

extension PortSignal {
    static let audio = PortSignal("audio")
    static let midi = PortSignal("midi")
}

/// How the adapter treats a node, derived from its payload.
enum AudioNodeRole: Equatable {
    case source              // the audio file player
    case midiInput           // the virtual destination or an external MIDI source
    case plugin(AudioUnitType)
    case output              // hardware output
    case generic             // carries a payload but no signal
}

enum AudioGraphError: LocalizedError {
    case feedbackLoop

    var errorDescription: String? {
        "That connection would make a loop back into the same chain."
    }
}

/// Audio and MIDI routing adapter over a VisualMesh graph.
///
/// `mesh` and `layout` are the model. The engine, player, Audio Units, MIDI
/// connections, and per-edge telemetry are runtime objects, rebuilt from the
/// model after every edit made through this type.
@Observable
final class AudioGraph {
    typealias GraphMesh = Mesh<Payload, AudioConnection>

    let mesh = GraphMesh()
    let layout = MeshLayout2D()
    @ObservationIgnored let runtimes = PayloadRuntimeStore()
    /// Live telemetry per audio edge ID.
    private(set) var signals: [UUID: SignalEdgePayload] = [:]

    // MARK: - Audio engine

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    @ObservationIgnored private var sumMixers: [UUID: AVAudioMixerNode] = [:]

    private(set) var audioFile: AVAudioFile?
    private(set) var audioFileURL: URL?
    private(set) var audioFileName: String = "No audio loaded"
    private(set) var isPlaying = false
    private(set) var isEngineRunning = false
    private(set) var lastError: String?
    var hasLoadedAudioFile: Bool { audioFile != nil }
    private(set) var hasPlayableRoute = false
    var canTogglePlayback: Bool { isPlaying || (hasLoadedAudioFile && hasPlayableRoute) }
    @ObservationIgnored private var telemetryTapNodes: [AVAudioNode] = []

    // MARK: - MIDI

    @ObservationIgnored private let midi = MIDIManager(clientName: "VisuSig Graph",
                                                      model: "VisuSig", manufacturer: "VisuSig")
    @ObservationIgnored private var midiStarted = false
    /// MIDI input node → plug-in nodes its events go to.
    @ObservationIgnored private var midiRoutes: [UUID: [UUID]] = [:]
    /// External MIDI sources available for MIDI Input nodes.
    private(set) var midiSources: [MIDIOutputEndpoint] = []
    /// Name of the virtual destination other apps can send to.
    static let virtualInputName = "VisuSig Graph In"

    init() {
        engine.attach(player)
    }

    /// A source and an output, ready to be wired directly or through effects.
    static func makeDefault() -> AudioGraph {
        let graph = AudioGraph()
        graph.addAudioFileSource(at: CGPoint(x: 0, y: -220))
        graph.addNode(
            payload: Payload(kind: .audioOutput, title: "Output"),
            ports: [GraphPort(name: "In", direction: .input, signal: .audio)],
            at: CGPoint(x: 0, y: 220)
        )
        return graph
    }

    // MARK: - Roles and runtimes

    func role(of node: GraphNode<Payload>) -> AudioNodeRole {
        switch node.payload.kind {
        case .audioFilePlayer: return .source
        case .midiInput: return .midiInput
        case .audioOutput: return .output
        case .appleAudioUnit:
            let type = node.payload[field: "audioUnitType"].flatMap(Int.init).flatMap(AudioUnitType.init)
            return .plugin(type ?? .effect)
        default: return .generic
        }
    }

    func managedAudioUnit(for node: GraphNode<Payload>) -> AUManagedUnit? {
        runtimes.runtime(for: node.payload.id, as: AUManagedUnit.self)
    }

    func signal(for edgeID: UUID) -> SignalEdgePayload? {
        signals[edgeID]
    }

    var hasAudioFileSource: Bool {
        mesh.nodes.contains { role(of: $0) == .source }
    }

    // MARK: - Graph editing

    @discardableResult
    func addNode(payload: Payload, ports: [GraphPort], at position: CGPoint) -> GraphNode<Payload> {
        let node = GraphNode(title: payload.title, payload: payload, ports: ports)
        mesh.addNode(node)
        layout.setPosition(position, for: node.id)
        return node
    }

    /// The single file player; there is one transport.
    func addAudioFileSource(at position: CGPoint) {
        guard !hasAudioFileSource else { return }
        addNode(payload: Payload(kind: .audioFilePlayer, title: "Audio Source"),
                ports: [GraphPort(name: "Out", direction: .output, signal: .audio)],
                at: position)
    }

    func addMIDIInput(at position: CGPoint) {
        addNode(payload: Payload(kind: .midiInput, title: Self.virtualInputName,
                                 fields: [PayloadField("source", value: "")]),
                ports: [GraphPort(name: "MIDI Out", direction: .output, signal: .midi)],
                at: position)
        refreshMIDISources()
        rebuildConnections()
    }

    /// Adds any Audio Unit kind with ports that match what it carries.
    func addPlugin(_ unit: AUManagedUnit, at position: CGPoint) {
        let type = unit.audioUnitType
        let payload = Payload(
            kind: .appleAudioUnit,
            title: unit.name,
            fields: [
                PayloadField("manufacturer", value: unit.protoType?.mfg ?? "Unknown"),
                PayloadField("audioUnitType", value: String(type.rawValue)),
            ]
        )
        var ports: [GraphPort] = []
        if type.takesAudio { ports.append(GraphPort(name: "In", direction: .input, signal: .audio)) }
        if type.takesMIDI { ports.append(GraphPort(name: "MIDI In", direction: .input, signal: .midi)) }
        if type.producesAudio { ports.append(GraphPort(name: "Out", direction: .output, signal: .audio)) }
        if type.producesMIDI { ports.append(GraphPort(name: "MIDI Out", direction: .output, signal: .midi)) }
        runtimes.register(unit, for: payload.id)
        addNode(payload: payload, ports: ports, at: position)
    }

    func addGenericNode(at position: CGPoint) {
        addNode(payload: Payload(title: "Payload"),
                ports: [GraphPort(name: "Port", direction: .output)],
                at: position)
    }

    func addPort(to nodeID: UUID, direction: PortDirection, signal: PortSignal) {
        guard let node = mesh.node(id: nodeID) else { return }
        let prefix = signal == .midi ? "MIDI " : ""
        let base = direction == .input ? "In" : "Out"
        let number = node.ports.filter { $0.direction == direction && $0.signal == signal }.count + 1
        node.ports.append(GraphPort(name: "\(prefix)\(base) \(number)", direction: direction, signal: signal))
    }

    func connect(source: GraphEndpoint, target: GraphEndpoint) throws {
        // A wire from the target back to the source would loop forever.
        if reaches(from: target.nodeID, to: source.nodeID) { throw AudioGraphError.feedbackLoop }
        let edge = try mesh.connect(
            sourceNodeID: source.nodeID, sourcePortID: source.portID,
            targetNodeID: target.nodeID, targetPortID: target.portID,
            payload: AudioConnection()
        )
        if signalKind(of: edge) == .audio { signals[edge.id] = SignalEdgePayload() }
        rebuildConnections()
    }

    func removeEdge(id: UUID) {
        mesh.removeEdge(id: id)
        signals[id] = nil
        rebuildConnections()
    }

    func removeNodes(_ nodeIDs: Set<UUID>) {
        for id in nodeIDs {
            guard let node = mesh.node(id: id) else { continue }
            silence(node)
            if let avUnit = managedAudioUnit(for: node)?.avAudioUnit, avUnit.engine != nil {
                engine.detach(avUnit)
            }
            for edge in mesh.edges where edge.sourceNodeID == id || edge.targetNodeID == id {
                signals[edge.id] = nil
            }
            runtimes.removeRuntime(for: node.payload.id)
            mesh.removeNode(id: id)
            layout.removePosition(for: id)
        }
        rebuildConnections()
    }

    private func signalKind(of edge: GraphEdge<AudioConnection>) -> PortSignal? {
        mesh.port(at: GraphEndpoint(nodeID: edge.sourceNodeID, portID: edge.sourcePortID))?.signal
    }

    private func reaches(from start: UUID, to goal: UUID) -> Bool {
        var stack = [start], seen: Set<UUID> = []
        while let current = stack.popLast() {
            if current == goal { return true }
            guard seen.insert(current).inserted else { continue }
            stack += mesh.edges.filter { $0.sourceNodeID == current }.map(\.targetNodeID)
        }
        return false
    }

    // MARK: - MIDI sources

    func refreshMIDISources() {
        do {
            try startMIDIIfNeeded()
            midiSources = midi.endpoints.outputs
        } catch {
            lastError = "MIDI: \(error.localizedDescription)"
        }
    }

    /// Chooses what a MIDI Input node listens to; `nil` is the virtual input.
    func setMIDISource(_ source: MIDIOutputEndpoint?, for nodeID: UUID) {
        guard let node = mesh.node(id: nodeID) else { return }
        node.payload[field: "source"] = source.map { "\($0.uniqueID)" } ?? ""
        node.title = source?.displayName ?? Self.virtualInputName
        node.payload.title = node.title
        rebuildMIDIConnections()
    }

    func isMIDISource(_ source: MIDIOutputEndpoint?, selectedFor node: GraphNode<Payload>) -> Bool {
        (node.payload[field: "source"] ?? "") == (source.map { "\($0.uniqueID)" } ?? "")
    }

    private func startMIDIIfNeeded() throws {
        guard !midiStarted else { return }
        try midi.start()
        midiStarted = true
    }

    /// One virtual destination for nodes without an external source, plus one
    /// managed connection per node that names one.
    private func rebuildMIDIConnections() {
        let inputs = mesh.nodes.filter { role(of: $0) == .midiInput }
        guard !inputs.isEmpty || midiStarted else { return }
        do {
            try startMIDIIfNeeded()
            midi.removeAll()
            guard !inputs.isEmpty else { return }

            let virtualNodes = inputs.filter { ($0.payload[field: "source"] ?? "").isEmpty }.map(\.id)
            if !virtualNodes.isEmpty {
                try midi.addInput(name: Self.virtualInputName, tag: "graph-virtual",
                                  uniqueID: .userDefaultsManaged(key: "visusig.graph.midi.input"),
                                  receiver: receiver(for: virtualNodes))
            }
            midiSources = midi.endpoints.outputs
            for node in inputs {
                let wanted = node.payload[field: "source"] ?? ""
                guard !wanted.isEmpty,
                      let endpoint = midiSources.first(where: { "\($0.uniqueID)" == wanted }) else { continue }
                try midi.addInputConnection(
                    to: .outputs(matching: [.uniqueID(endpoint.uniqueID)]),
                    tag: "graph-\(node.id.uuidString)",
                    receiver: receiver(for: [node.id])
                )
            }
        } catch {
            lastError = "MIDI: \(error.localizedDescription)"
        }
    }

    private func receiver(for nodeIDs: [UUID]) -> MIDIReceiver {
        MIDIReceiver.events(options: [.filterActiveSensingAndClock]) { [weak self] events, _, _ in
            let messages = events.map { $0.midi1RawBytes() }
            DispatchQueue.main.async {
                guard let self else { return }
                for nodeID in nodeIDs {
                    for message in messages { self.deliver(message, from: nodeID) }
                }
            }
        }
    }

    private func deliver(_ message: [UInt8], from inputNodeID: UUID) {
        guard let status = message.first, (0x80 ... 0xEF).contains(status) else { return }
        for targetID in midiRoutes[inputNodeID] ?? [] {
            guard let node = mesh.node(id: targetID) else { continue }
            send(message, to: node)
        }
    }

    private func send(_ message: [UInt8], to node: GraphNode<Payload>) {
        guard let schedule = managedAudioUnit(for: node)?.audioUnit?.scheduleMIDIEventBlock else { return }
        message.withUnsafeBufferPointer { bytes in
            guard let start = bytes.baseAddress else { return }
            schedule(AUEventSampleTimeImmediate, 0, bytes.count, start)
        }
    }

    /// All sound off and all notes off on every channel, for plug-ins that
    /// take MIDI.
    private func silence(_ node: GraphNode<Payload>) {
        guard case .plugin(let type) = role(of: node), type.takesMIDI else { return }
        for channel in UInt8(0) ..< 16 {
            send([0xB0 | channel, 64, 0], to: node)
            send([0xB0 | channel, 120, 0], to: node)
            send([0xB0 | channel, 123, 0], to: node)
        }
    }

    /// Plays middle C for a moment on an instrument or MIDI-driven node.
    func playTestNote(on nodeID: UUID) {
        guard let node = mesh.node(id: nodeID) else { return }
        send([0x90, 60, 96], to: node)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.send([0x80, 60, 0], to: node)
        }
    }

    // MARK: - File loading

    @discardableResult
    func loadAudioFile(url: URL) -> Bool {
        let wasPlaying = isPlaying
        if wasPlaying { stopPlayingInternal() }
        do {
            audioFile = try AVAudioFile(forReading: url)
            audioFileURL = url
            audioFileName = url.lastPathComponent
            rebuildConnections()
            if wasPlaying { startPlayingInternal() }
            return true
        } catch {
            lastError = "Couldn't open \(url.lastPathComponent): \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Playback

    func togglePlay() -> Bool {
        if isPlaying { stopPlayingInternal() } else { startPlayingInternal() }
        return isPlaying
    }

    func startPlayingInternal() {
        guard !isPlaying, let audioFile, hasPlayableRoute else { return }
        startEngine()
        guard isEngineRunning else { return }
        scheduleFileLoop(file: audioFile)
        player.play()
        isPlaying = true
    }

    /// Stops the file player only; instruments keep sounding.
    func stopPlayingInternal() {
        guard isPlaying else { return }
        isPlaying = false
        player.stop()
    }

    private func scheduleFileLoop(file: AVAudioFile) {
        player.scheduleFile(file, at: nil) { [weak self] in
            DispatchQueue.main.async {
                guard let self, self.isPlaying else { return }
                self.scheduleFileLoop(file: file)
            }
        }
    }

    private func startEngine() {
        guard !engine.isRunning else { isEngineRunning = true; return }
        engine.prepare()
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            isEngineRunning = false
            lastError = "Audio engine couldn't start: \(error.localizedDescription)"
        }
    }

    // MARK: - Rebuilding from the graph

    /// Tears down all routing and rebuilds it from the graph: audio wires as
    /// engine connections (mixing where several wires meet), MIDI wires from
    /// MIDI Input nodes as event routes, and MIDI wires out of MIDI effects
    /// as engine MIDI connections.
    func rebuildConnections() {
        let wasPlaying = isPlaying
        for node in mesh.nodes { silence(node) }
        if wasPlaying {
            player.stop()
            isPlaying = false
        }
        engine.stop()
        isEngineRunning = false
        removeTelemetryTaps()

        for node in mesh.nodes {
            if let avUnit = managedAudioUnit(for: node)?.avAudioUnit, avUnit.engine != nil {
                engine.detach(avUnit)
            }
        }
        for mixer in sumMixers.values { engine.detach(mixer) }
        sumMixers = [:]
        engine.disconnectNodeOutput(player)
        engine.disconnectNodeInput(engine.mainMixerNode)

        for node in mesh.nodes {
            if case .plugin = role(of: node), let avUnit = managedAudioUnit(for: node)?.avAudioUnit {
                engine.attach(avUnit)
            }
        }

        let audioEdges = mesh.edges.filter { signalKind(of: $0) == .audio }
        let midiEdges = mesh.edges.filter { signalKind(of: $0) == .midi }

        // Several audio wires into one effect are summed by a mixer first.
        let incoming = Dictionary(grouping: audioEdges, by: \.targetNodeID)
        var nextBus: [ObjectIdentifier: AVAudioNodeBus] = [:]
        for (targetID, edges) in incoming where edges.count > 1 {
            guard let target = mesh.node(id: targetID), role(of: target) != .output,
                  let targetAV = avAudioNode(for: target) else { continue }
            let mixer = AVAudioMixerNode()
            engine.attach(mixer)
            engine.connect(mixer, to: targetAV, format: nil)
            sumMixers[targetID] = mixer
        }

        func destination(for edge: GraphEdge<AudioConnection>) -> AVAudioConnectionPoint? {
            guard let target = mesh.node(id: edge.targetNodeID) else { return nil }
            let node: AVAudioNode
            if role(of: target) == .output {
                node = engine.mainMixerNode
            } else if let mixer = sumMixers[target.id] {
                node = mixer
            } else if let av = avAudioNode(for: target) {
                node = av
            } else {
                return nil
            }
            let key = ObjectIdentifier(node)
            // The main mixer and summing mixers take one bus per wire.
            let bus: AVAudioNodeBus = node is AVAudioMixerNode ? (nextBus[key] ?? 0) : 0
            if node is AVAudioMixerNode { nextBus[key] = bus + 1 }
            return AVAudioConnectionPoint(node: node, bus: bus)
        }

        for (sourceID, edges) in Dictionary(grouping: audioEdges, by: \.sourceNodeID) {
            guard let source = mesh.node(id: sourceID), let sourceAV = avAudioNode(for: source) else { continue }
            let points = edges.compactMap(destination(for:))
            guard !points.isEmpty else { continue }
            let format = role(of: source) == .source ? audioFile?.processingFormat : nil
            engine.connect(sourceAV, to: points, fromBus: 0, format: format)
        }

        // MIDI effects feed their targets inside the engine.
        midiRoutes = [:]
        for edge in midiEdges {
            guard let source = mesh.node(id: edge.sourceNodeID),
                  let target = mesh.node(id: edge.targetNodeID) else { continue }
            switch role(of: source) {
            case .midiInput:
                midiRoutes[source.id, default: []].append(target.id)
            case .plugin(.midiEffect):
                if let sourceAV = avAudioNode(for: source), let targetAV = avAudioNode(for: target) {
                    engine.connectMIDI(sourceAV, to: targetAV, format: nil, eventListBlock: nil)
                }
            default:
                break
            }
        }

        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hwFormat)
        installTelemetryTaps(for: audioEdges)

        let outputs = Set(mesh.nodes.filter { role(of: $0) == .output }.map(\.id))
        let fileSource = mesh.nodes.first { role(of: $0) == .source }
        hasPlayableRoute = fileSource.map { source in
            outputs.contains { reachesByAudio(from: source.id, to: $0, audioEdges) }
        } ?? false

        // Run the engine whenever anything is wired to an output, so
        // instruments sound without pressing Play.
        if audioEdges.contains(where: { outputs.contains($0.targetNodeID) }) {
            startEngine()
        }
        rebuildMIDIConnections()
        if wasPlaying && hasPlayableRoute { startPlayingInternal() }
    }

    private func reachesByAudio(from start: UUID, to goal: UUID, _ edges: [GraphEdge<AudioConnection>]) -> Bool {
        var stack = [start], seen: Set<UUID> = []
        while let current = stack.popLast() {
            if current == goal { return true }
            guard seen.insert(current).inserted else { continue }
            stack += edges.filter { $0.sourceNodeID == current }.map(\.targetNodeID)
        }
        return false
    }

    // MARK: - Edge telemetry

    private func installTelemetryTaps(for audioEdges: [GraphEdge<AudioConnection>]) {
        var signalsByNode: [ObjectIdentifier: (node: AVAudioNode, signals: [SignalEdgePayload])] = [:]
        for edge in audioEdges {
            guard let source = mesh.node(id: edge.sourceNodeID),
                  let audioNode = avAudioNode(for: source),
                  let signal = signals[edge.id] else { continue }
            let key = ObjectIdentifier(audioNode)
            if signalsByNode[key] == nil { signalsByNode[key] = (audioNode, []) }
            signalsByNode[key]?.signals.append(signal)
        }

        for entry in signalsByNode.values {
            let observed = entry.signals
            let format = entry.node.outputFormat(forBus: 0)
            guard format.channelCount > 0 else { continue }
            entry.node.installTap(onBus: 0, bufferSize: 1_024, format: format) { buffer, _ in
                guard let channel = buffer.floatChannelData?.pointee else { return }
                let frameCount = Int(buffer.frameLength)
                guard frameCount > 0 else { return }

                var squaredSum: Float = 0
                var zeroCrossings = 0
                var previous = channel[0]
                for index in 0 ..< frameCount {
                    let sample = channel[index]
                    squaredSum += sample * sample
                    if (sample >= 0) != (previous >= 0) { zeroCrossings += 1 }
                    previous = sample
                }

                let rms = sqrt(Double(squaredSum) / Double(frameCount))
                let frequency = Double(zeroCrossings) * buffer.format.sampleRate / (2 * Double(frameCount))

                DispatchQueue.main.async {
                    for signal in observed { signal.publish(voltage: rms, frequency: frequency) }
                }
            }
            telemetryTapNodes.append(entry.node)
        }
    }

    private func removeTelemetryTaps() {
        for node in telemetryTapNodes { node.removeTap(onBus: 0) }
        telemetryTapNodes.removeAll()
    }

    // MARK: - Node → AVAudioNode

    private func avAudioNode(for node: GraphNode<Payload>) -> AVAudioNode? {
        switch role(of: node) {
        case .source: return player
        case .output: return engine.mainMixerNode
        case .plugin: return managedAudioUnit(for: node)?.avAudioUnit
        case .midiInput, .generic: return nil
        }
    }
}
