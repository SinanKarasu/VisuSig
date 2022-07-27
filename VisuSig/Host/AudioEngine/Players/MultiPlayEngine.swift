/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple playback engine built on AVAudioEngine and its related classes.
*/

import AVFoundation

public class MultiPlayEngine {
    
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
    
    // Whether we are playing.
    private var isPlaying = false
    
    // This block will be called every render cycle and will receive MIDI events
    private let midiOutBlock: AUMIDIOutputEventBlock = { sampleTime, cable, length, data in return noErr }

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

        guard let fileURL = Bundle.main.url(forResource: "Synth", withExtension: "aif") else {
            fatalError("\"Synth.aif\" file not found.")
        }
        setPlayerFile(fileURL)

        engine.prepare()
    }

    private func setPlayerFile(_ fileURL: URL) {
        do {
            let file = try AVAudioFile(forReading: fileURL)
            self.file = file
            engine.connect(player, to: engine.mainMixerNode, format: file.processingFormat)
        } catch {
            fatalError("Could not create AVAudioFile instance. error: \(error).")
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
            fatalError("Could not start engine. error: \(error).")
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
        guard let file = file else {
            fatalError("`file` must not be nil in \(#function).")
        }
        
        player.scheduleFile(file, at: nil) {
            self.stateChangeQueue.async {
                if self.isPlaying {
                    self.scheduleEffectLoop()
                }
            }
        }
    }

    private func resetAudioLoop() {
        if isEffect {
            // Connect player -> mixer.
            guard let format = file?.processingFormat else { fatalError("No AVAudioFile defined (processing format unavailable).") }
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
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
                //print("engine:\(engine)")
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

        let auAudioUnit = avAudioUnit.auAudioUnit

        if !auAudioUnit.midiOutputNames.isEmpty {
            auAudioUnit.midiOutputEventBlock = midiOutBlock
        }

        // Attach the AVAudioUnit the the graph.
        engine.attach(avAudioUnit)

        if isEffect {
            // Disconnect the player -> mixer.
            engine.disconnectNodeInput(engine.mainMixerNode)

            // Connect the player -> effect -> mixer.
            if let format = file?.processingFormat {
                engine.connect(player, to: avAudioUnit, format: format)
                engine.connect(avAudioUnit, to: engine.mainMixerNode, format: format)
            }
        } else {
            let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareFormat.sampleRate, channels: 2)
            engine.connect(avAudioUnit, to: engine.mainMixerNode, format: stereoFormat)
        }
        rewiringComplete()
    }

    // MARK: InstrumentPlayer

    /// Simple MIDI note generator that plays a two-octave scale.

}

