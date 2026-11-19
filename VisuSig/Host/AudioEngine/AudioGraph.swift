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
import VisualMesh
import VisualMeshUI

/// Durable description of an audio wire. Live telemetry for a wire is kept by
/// `AudioGraph`, keyed by the edge's ID, and never stored in the edge.
struct AudioConnection: Codable, Hashable, Sendable {}

/// How the audio adapter treats a node, derived from its payload kind.
enum AudioNodeRole {
    case source   // audio file player that feeds the chain
    case effect   // Audio Unit effect
    case output   // hardware output
    case generic  // carries a payload but no audio
}

/// Audio-routing adapter over a VisualMesh graph.
///
/// `mesh` and `layout` are the model. The engine, player, Audio Units, and
/// per-edge telemetry are runtime objects, rebuilt from the model after
/// every edit made through this type.
@Observable
final class AudioGraph {
    typealias GraphMesh = Mesh<Payload, AudioConnection>

    let mesh = GraphMesh()
    let layout = MeshLayout2D()
    @ObservationIgnored let runtimes = PayloadRuntimeStore()
    /// Live telemetry per edge ID.
    private(set) var signals: [UUID: SignalEdgePayload] = [:]

    // MARK: - Audio engine

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()

    private(set) var audioFile: AVAudioFile?
    private(set) var audioFileURL: URL?
    private(set) var audioFileName: String = "No audio loaded"
    private(set) var isPlaying = false
    var hasLoadedAudioFile: Bool { audioFile != nil }
    private(set) var hasPlayableRoute = false
    var canTogglePlayback: Bool { isPlaying || (hasLoadedAudioFile && hasPlayableRoute) }
    @ObservationIgnored private var telemetryTapNodes: [AVAudioNode] = []

    init() {
        engine.attach(player)
    }

    /// A source and an output, ready to be wired directly or through effects.
    static func makeDefault() -> AudioGraph {
        let graph = AudioGraph()
        graph.addNode(
            payload: Payload(kind: .audioFilePlayer, title: "Audio Source"),
            ports: [GraphPort(name: "Out", direction: .output)],
            at: CGPoint(x: 0, y: -220)
        )
        graph.addNode(
            payload: Payload(kind: .audioOutput, title: "Output"),
            ports: [GraphPort(name: "In", direction: .input)],
            at: CGPoint(x: 0, y: 220)
        )
        return graph
    }

    // MARK: - Roles and runtimes

    func role(of node: GraphNode<Payload>) -> AudioNodeRole {
        switch node.payload.kind {
        case .audioFilePlayer: return .source
        case .audioOutput: return .output
        case .appleAudioUnit: return .effect
        default: return .generic
        }
    }

    func managedAudioUnit(for node: GraphNode<Payload>) -> AUManagedUnit? {
        runtimes.runtime(for: node.payload.id, as: AUManagedUnit.self)
    }

    func signal(for edgeID: UUID) -> SignalEdgePayload? {
        signals[edgeID]
    }

    // MARK: - Graph editing

    @discardableResult
    func addNode(payload: Payload, ports: [GraphPort], at position: CGPoint) -> GraphNode<Payload> {
        let node = GraphNode(title: payload.title, payload: payload, ports: ports)
        mesh.addNode(node)
        layout.setPosition(position, for: node.id)
        return node
    }

    func addEffect(_ unit: AUManagedUnit, at position: CGPoint) {
        let payload = Payload(
            kind: .appleAudioUnit,
            title: unit.name,
            fields: [
                PayloadField("manufacturer", value: unit.protoType?.mfg ?? "Unknown"),
                PayloadField("audioUnitType", value: String(describing: unit.audioUnitType.rawValue)),
            ]
        )
        runtimes.register(unit, for: payload.id)
        addNode(payload: payload,
                ports: [GraphPort(name: "In", direction: .input),
                        GraphPort(name: "Out", direction: .output)],
                at: position)
    }

    func addGenericNode(at position: CGPoint) {
        addNode(payload: Payload(title: "Payload"),
                ports: [GraphPort(name: "Port", direction: .output)],
                at: position)
    }

    func addPort(to nodeID: UUID, direction: PortDirection) {
        guard let node = mesh.node(id: nodeID) else { return }
        let number = node.ports.filter { $0.direction == direction }.count + 1
        node.ports.append(GraphPort(name: direction == .input ? "In \(number)" : "Out \(number)",
                                    direction: direction))
    }

    func connect(source: GraphEndpoint, target: GraphEndpoint) throws {
        let edge = try mesh.connect(
            sourceNodeID: source.nodeID, sourcePortID: source.portID,
            targetNodeID: target.nodeID, targetPortID: target.portID,
            payload: AudioConnection()
        )
        signals[edge.id] = SignalEdgePayload()
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

    // MARK: - File loading

    /// Load a user-chosen audio file.
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
            print("AudioGraph: failed to load \(url.lastPathComponent): \(error)")
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

        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hwFormat)

        engine.prepare()
        do {
            try engine.start()
            scheduleFileLoop(file: audioFile)
            player.play()
            isPlaying = true
        } catch {
            print("AudioGraph: engine start failed: \(error)")
        }
    }

    func stopPlayingInternal() {
        guard isPlaying else { return }
        player.stop()
        engine.stop()
        isPlaying = false
    }

    private func scheduleFileLoop(file: AVAudioFile) {
        player.scheduleFile(file, at: nil) { [weak self] in
            guard let self, self.isPlaying else { return }
            self.scheduleFileLoop(file: file)
        }
    }

    // MARK: - Connection rebuilding

    /// Tears down all Audio Unit connections and rebuilds them from the graph.
    func rebuildConnections() {
        let wasPlaying = isPlaying
        if wasPlaying { stopPlayingInternal() }

        removeTelemetryTaps()
        engine.disconnectNodeOutput(player)

        for node in mesh.nodes {
            if let avUnit = managedAudioUnit(for: node)?.avAudioUnit, avUnit.engine != nil {
                engine.detach(avUnit)
            }
        }
        for node in mesh.nodes where role(of: node) == .effect {
            if let avUnit = managedAudioUnit(for: node)?.avAudioUnit {
                engine.attach(avUnit)
            }
        }

        let format = audioFile?.processingFormat
            ?? AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        let chain = buildAudioChain()
        hasPlayableRoute = chain.count >= 2
        if hasPlayableRoute {
            for i in 0 ..< chain.count - 1 {
                guard let fromAV = avAudioNode(for: chain[i]),
                      let toAV = avAudioNode(for: chain[i + 1]) else { continue }
                engine.connect(fromAV, to: toAV, format: format)
            }
        }
        // Without a complete source → output chain the player stays
        // disconnected, so audio stops when a wire is removed.

        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hwFormat)

        installTelemetryTaps(format: format)
        engine.prepare()
        if wasPlaying && hasPlayableRoute { startPlayingInternal() }
    }

    // MARK: - Edge telemetry

    private func installTelemetryTaps(format: AVAudioFormat) {
        var signalsByNode: [ObjectIdentifier: (node: AVAudioNode, signals: [SignalEdgePayload])] = [:]

        for edge in mesh.edges {
            guard let source = mesh.node(id: edge.sourceNodeID),
                  let audioNode = avAudioNode(for: source),
                  let signal = signals[edge.id] else { continue }
            let key = ObjectIdentifier(audioNode)
            if signalsByNode[key] == nil {
                signalsByNode[key] = (audioNode, [])
            }
            signalsByNode[key]?.signals.append(signal)
        }

        for entry in signalsByNode.values {
            let observed = entry.signals
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
                    if (sample >= 0) != (previous >= 0) {
                        zeroCrossings += 1
                    }
                    previous = sample
                }

                let rms = sqrt(Double(squaredSum) / Double(frameCount))
                let frequency = Double(zeroCrossings) * buffer.format.sampleRate
                    / (2 * Double(frameCount))

                DispatchQueue.main.async {
                    for signal in observed {
                        signal.publish(voltage: rms, frequency: frequency)
                    }
                }
            }
            telemetryTapNodes.append(entry.node)
        }
    }

    private func removeTelemetryTaps() {
        for node in telemetryTapNodes {
            node.removeTap(onBus: 0)
        }
        telemetryTapNodes.removeAll()
    }

    // MARK: - Chain building

    /// Follows edges from the source node: [source, effect…, output].
    /// Edges are already oriented source → target by the graph model.
    private func buildAudioChain() -> [GraphNode<Payload>] {
        guard let sourceNode = mesh.nodes.first(where: { role(of: $0) == .source }) else { return [] }

        var chain = [sourceNode]
        var visited: Set<UUID> = [sourceNode.id]
        var current = sourceNode

        while let next = mesh.edges
            .first(where: { $0.sourceNodeID == current.id })
            .flatMap({ mesh.node(id: $0.targetNodeID) }),
            !visited.contains(next.id) {
            visited.insert(next.id)
            chain.append(next)
            if role(of: next) == .output { break }
            current = next
        }

        guard role(of: chain.last!) == .output, chain.count >= 2 else { return [] }
        return chain
    }

    // MARK: - Node → AVAudioNode

    private func avAudioNode(for node: GraphNode<Payload>) -> AVAudioNode? {
        switch role(of: node) {
        case .source: return player
        case .output: return engine.mainMixerNode
        case .effect: return managedAudioUnit(for: node)?.avAudioUnit
        case .generic: return nil
        }
    }
}
