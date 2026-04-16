/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple playback engine built on AVAudioEngine and its related classes.
*/

import AVFoundation

public class SimplePlayEngine {
    // The engine's active unit node.
    private var activeAVAudioUnit: AVAudioUnit?

    private var instrumentPlayer: InstrumentPlayer?

    // Synchronizes starting/stopping the engine and scheduling file segments.
    private let stateChangeQueue = DispatchQueue(label: "com.example.apple-samplecode.StateChangeQueue")

    // Playback engine.
    private let engine = AVAudioEngine()

    // Engine's player node.
    private let player = AVAudioPlayerNode()

    // File to play.
    private var file: AVAudioFile?
    public private(set) var fileName = "No audio loaded"
    public var hasLoadedFile: Bool { file != nil }

    // Whether we are playing.
    private var isPlaying = false

    private var componentType: OSType {
        return activeAVAudioUnit?.audioComponentDescription.componentType ?? kAudioUnitType_Effect
    }

    private var isEffect: Bool {
        // SimplePlayEngine only supports effects or instruments.
        // If it's not an instrument, it's an effect
        return !isInstrument
    }

    private var isInstrument: Bool {
        return componentType == kAudioUnitType_MusicDevice
    }

    // MARK: Initialization

    public init() {
        engine.attach(player)
    }

    public func loadAudioFile(_ fileURL: URL) {
        let wasPlaying = isPlaying
        if wasPlaying {
            stopPlaying()
        }
        do {
            let file = try AVAudioFile(forReading: fileURL)
            self.file = file
            fileName = fileURL.lastPathComponent
            resetAudioLoop()
        } catch {
            file = nil
            fileName = "No audio loaded"
            print("SimplePlayEngine: failed to load \(fileURL.lastPathComponent): \(error)")
        }

        if wasPlaying && hasLoadedFile {
            startPlaying()
        }
    }

    // MARK: Playback State

    public func startPlaying() {
        stateChangeQueue.sync {
            if !self.isPlaying { self.startPlayingInternal() }
        }
    }

    public func stopPlaying() {
        stateChangeQueue.sync {
            if self.isPlaying { self.stopPlayingInternal() }
        }
    }

    public func togglePlay() -> Bool {
        if isPlaying {
            stopPlaying()
        } else {
            startPlaying()
        }
        return isPlaying
    }

    private func startPlayingInternal() {
        // assumptions: we are protected by stateChangeQueue. we are not playing.
        guard hasLoadedFile || isInstrument else { return }

        if isEffect {
            // Schedule buffers on the player.
            scheduleEffectLoop()
            scheduleEffectLoop()
        }

        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

        // Start the engine.
        do {
            try engine.start()
        } catch {
            isPlaying = false
            print("SimplePlayEngine: could not start engine: \(error)")
            return
        }

        if isEffect {
            // Start the player.
            player.play()
        } else if isInstrument {
            instrumentPlayer = InstrumentPlayer(audioUnit: activeAVAudioUnit?.auAudioUnit)
            instrumentPlayer?.play()
        }

        isPlaying = true
    }

    private func stopPlayingInternal() {
        if isEffect {
            player.stop()
        } else if isInstrument {
            instrumentPlayer?.stop()
        }
        engine.stop()
        isPlaying = false
    }

    private func scheduleEffectLoop() {
        guard let file else { return }

        player.scheduleFile(file, at: nil) {
            self.stateChangeQueue.async {
                if self.isPlaying {
                    self.scheduleEffectLoop()
                }
            }
        }
    }

    private func resetAudioLoop() {
        guard isEffect else { return }
        let format = file?.processingFormat ?? engine.outputNode.outputFormat(forBus: 0)
        engine.disconnectNodeOutput(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    public func reset() {
        connect(avAudioUnit: nil)
    }

    public func connect(avAudioUnit: AVAudioUnit?, completion: @escaping (() -> Void) = {}) {
        // If effect, ensure audio loop is reset (but only once per call to this method)
        var needsAudioLoopReset = true

        // Destroy the currently connected audio unit, if any.
        if let audioUnit = activeAVAudioUnit {
            if isEffect {
                // Break the player -> effect connection.
                // print("engine:\(engine)")
                engine.disconnectNodeInput(audioUnit)
            }

            // Break the audio unit -> mixer connection
            engine.disconnectNodeInput(engine.mainMixerNode)

            resetAudioLoop()
            needsAudioLoopReset = false

            // We're done with the unit; release all references.
            engine.detach(audioUnit)
        }

        activeAVAudioUnit = avAudioUnit

        // Internal function to resume playing and call the completion handler.
        func rewiringComplete() {
            if isEffect && isPlaying {
                player.play()
            } else if isInstrument && isPlaying {
                instrumentPlayer = InstrumentPlayer(audioUnit: activeAVAudioUnit?.auAudioUnit)
                instrumentPlayer?.play()
            }
            completion()
        }

        let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)

        // Connect the main mixer -> output node
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)

        // Pause the player before re-wiring it. It is not simple to keep it playing across an insertion or deletion.
        if isEffect && isPlaying {
            player.pause()
        } else if isInstrument && isPlaying {
            instrumentPlayer?.stop()
            instrumentPlayer = nil
        }

        guard let avAudioUnit = avAudioUnit else {
            if needsAudioLoopReset { resetAudioLoop() }
            rewiringComplete()
            return
        }

        // Attach the AVAudioUnit the the graph.
        engine.attach(avAudioUnit)

        if isEffect {
            // Disconnect the player -> mixer.
            engine.disconnectNodeInput(engine.mainMixerNode)

            // Connect the player -> effect -> mixer.
            let format = file?.processingFormat ?? hardwareFormat
            engine.connect(player, to: avAudioUnit, format: format)
            engine.connect(avAudioUnit, to: engine.mainMixerNode, format: format)
        } else {
            let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareFormat.sampleRate, channels: 2)
            engine.connect(avAudioUnit, to: engine.mainMixerNode, format: stereoFormat)
        }
        rewiringComplete()
    }

    // MARK: InstrumentPlayer

    /// Simple MIDI note generator that plays a two-octave scale.

}
