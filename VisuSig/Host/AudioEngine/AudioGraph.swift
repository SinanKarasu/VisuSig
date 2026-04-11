//
//  AudioGraph.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/11/22.
//

import Foundation
import AVFoundation
import AudioToolbox

/// AudioGraph extends Mesh so the visual node graph IS the audio routing graph.
/// When the user connects ports visually, AVAudioEngine connections are rebuilt automatically.
@Observable
class AudioGraph: Mesh {

    // MARK: - Audio engine

    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()

    private(set) var audioFile: AVAudioFile?
    private(set) var audioFileName: String = "Synth.aif"
    private(set) var isPlaying = false

    private let stateQueue = DispatchQueue(label: "com.visusig.audioGraphState")

    // MARK: - Init

    override init() {
        super.init()
        engine.attach(player)
        loadBundleFile()
    }

    // MARK: - File loading

    /// Load the default bundled audio file.
    func loadBundleFile() {
        if let url = Bundle.main.url(forResource: "Synth", withExtension: "aif") {
            loadAudioFile(url: url)
            audioFileName = "Synth.aif"
        }
    }

    /// Load a user-chosen audio file.
    func loadAudioFile(url: URL) {
        let wasPlaying = isPlaying
        if wasPlaying { stopPlayingInternal() }
        do {
            audioFile = try AVAudioFile(forReading: url)
            audioFileName = url.lastPathComponent
            rebuildConnections()
            if wasPlaying { startPlayingInternal() }
        } catch {
            print("AudioGraph: failed to load \(url.lastPathComponent): \(error)")
        }
    }

    // MARK: - Mesh overrides (trigger audio rebuild on graph changes)

    override func connect(_ parent: PortBase, to child: PortBase) {
        super.connect(parent, to: child)
        rebuildConnections()
    }

    override func removeEdge(edge: EdgeBase) {
        super.removeEdge(edge: edge)
        rebuildConnections()
    }

    override func deleteNodes(_ nodesToDelete: [NodeBase]) {
        // Detach AV units before removing their nodes
        for node in nodesToDelete {
            if let avUnit = node.payload?.avAudioUnit, avUnit.engine != nil {
                engine.detach(avUnit)
            }
        }
        super.deleteNodes(nodesToDelete)
        rebuildConnections()
    }

    // MARK: - Playback

    func togglePlay() -> Bool {
        if isPlaying { stopPlayingInternal() } else { startPlayingInternal() }
        return isPlaying
    }

    func startPlayingInternal() {
        guard !isPlaying else { return }

        // Connect mainMixer → hardware output
        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hwFormat)

        engine.prepare()
        do {
            try engine.start()
            scheduleFileLoop()
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

    // MARK: - File loop scheduling

    private func scheduleFileLoop() {
        guard let file = audioFile else { return }
        player.scheduleFile(file, at: nil) { [weak self] in
            guard let self, self.isPlaying else { return }
            self.scheduleFileLoop()
        }
    }

    // MARK: - Connection rebuilding

    /// Tears down all AU connections and rebuilds them from the visual edge graph.
    func rebuildConnections() {
        let wasPlaying = isPlaying
        if wasPlaying { stopPlayingInternal() }

        // Step 1: Disconnect the player's output so we can re-route it.
        engine.disconnectNodeOutput(player)

        // Step 2: Detach all currently-attached effect units.
        for node in nodes {
            if let avUnit = node.payload?.avAudioUnit, avUnit.engine != nil {
                engine.detach(avUnit)   // also severs that node's connections
            }
        }

        // Step 3: Re-attach every effect node that is in the current mesh.
        for node in nodes where node.nodeRole == .effect {
            if let avUnit = node.payload?.avAudioUnit {
                engine.attach(avUnit)
            }
        }

        // Step 4: Determine audio format from the loaded file (or use a safe default).
        let format: AVAudioFormat
        if let file = audioFile {
            format = file.processingFormat
        } else {
            format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        }

        // Step 5: Walk the visual graph and build AVAudioEngine connections.
        let chain = buildAudioChain()
        let hasValidChain = chain.count >= 2
        if hasValidChain {
            for i in 0 ..< chain.count - 1 {
                guard let fromAV = avAudioNodeFor(chain[i]),
                      let toAV   = avAudioNodeFor(chain[i + 1]) else { continue }
                engine.connect(fromAV, to: toAV, format: format)
            }
        }
        // If no complete source→output chain exists, leave the player disconnected.
        // This means audio stops (correctly) when a wire is removed.

        // Step 6: Always connect mainMixer → hardware output.
        let hwFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hwFormat)

        engine.prepare()
        // Only restart playback if a complete chain was established.
        if wasPlaying && hasValidChain { startPlayingInternal() }
    }

    // MARK: - Chain building

    /// Walks the visual edges starting from the source node to build an ordered list:
    ///   [sourceNode, effect1, effect2, ..., outputNode]
    private func buildAudioChain() -> [NodeBase] {
        guard let sourceNode = nodes.first(where: { $0.nodeRole == .source }) else { return [] }

        var chain: [NodeBase] = [sourceNode]
        var current = sourceNode
        var visited = Set<UUID>()
        visited.insert(current.id)

        while true {
            // Find an edge leaving an output port of the current node
            guard let edge = edges.first(where: {
                $0.startPort.node.id == current.id && $0.startPort.portType == .output
            }) else { break }

            let next = edge.endPort.node
            guard !visited.contains(next.id) else { break }

            visited.insert(next.id)
            chain.append(next)
            if next.nodeRole == .output { break }
            current = next
        }

        // Valid only if it starts at source AND ends at output
        guard chain.first?.nodeRole == .source,
              chain.last?.nodeRole == .output,
              chain.count >= 2 else { return [] }

        return chain
    }

    // MARK: - Node → AVAudioNode mapping

    private func avAudioNodeFor(_ node: NodeBase) -> AVAudioNode? {
        switch node.nodeRole {
        case .source:  return player
        case .output:  return engine.mainMixerNode
        case .effect:  return node.payload?.avAudioUnit
        case .generic: return nil
        }
    }
}
