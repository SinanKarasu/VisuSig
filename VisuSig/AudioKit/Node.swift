// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

import AVFoundation

/// Node in an audio graph.
public protocol Node: AVAudioNode {

    /// Nodes providing audio input to this node.
    var connections: [Node] { get }

    /// Internal AVAudioEngine node.
//    var avAudioNode: AVAudioNode { get }
//
//    /// Start the node
//    func start()
//
//    /// Stop the node
//    func stop()
//
//    /// Bypass the node
//    func bypass()
//
//    /// Tells whether the node is processing (ie. started, playing, or active)
//    var isStarted: Bool { get }

}

public extension Node {
    /// Reset the internal state of the unit
    /// Fixes issues such as https://github.com/AudioKit/AudioKit/issues/2046
//    func reset() {
//        AudioUnitReset(auAudioUnit, kAudioUnitScope_Global, 0)
//        if let avAudioUnit = avAudioNode as? AVAudioUnit {
//            AudioUnitReset(avAudioUnit.audioUnit, kAudioUnitScope_Global, 0)
//        }
//    }

    /// Schedule an event with an offset
    ///
    /// - Parameters:
    ///   - event: MIDI Event to schedule
    ///   - offset: Time in samples
    ///
    func scheduleMIDIEvent(event: MIDIEvent, offset: UInt64 = 0) {
        if let midiBlock = self.auAudioUnit.scheduleMIDIEventBlock {
            event.data.withUnsafeBufferPointer { ptr in
                guard let ptr = ptr.baseAddress else { return }
                midiBlock(AUEventSampleTimeImmediate + AUEventSampleTime(offset), 0, event.data.count, ptr)
            }
        }
    }

    var isStarted: Bool { !bypassed }
    func start() { bypassed = false }
    func stop() { bypassed = true }
    func play() { bypassed = false }
    func bypass() { bypassed = true }

    /// All parameters on the Node
    var parameters: [NodeParameter] {

        let mirror = Mirror(reflecting: self)
        var params: [NodeParameter] = []

        for child in mirror.children {
            if let param = child.value as? ParameterBase {
                params.append(param.projectedValue)
            }
        }

        return params
    }

    /// Set up node parameters using reflection
    func setupParameters() {

        let mirror = Mirror(reflecting: self)
        var params: [AUParameter] = []

        for child in mirror.children {
            if let param = child.value as? ParameterBase {
                let def = param.projectedValue.def
                let auParam = AUParameterTree.createParameter(identifier: def.identifier,
                                                              name: def.name,
                                                              address: def.address,
                                                              range: def.range,
                                                              unit: def.unit,
                                                              flags: def.flags)
                params.append(auParam)
                param.projectedValue.associate(with: self, parameter: auParam)
            }
        }

        self.auAudioUnit.parameterTree = AUParameterTree.createTree(withChildren: params)
    }
}

extension Node {

    func detach() {
        if let engine = self.engine {
            engine.detach(self)
        }
        for connection in connections {
            connection.detach()
        }
    }

    func disconnectAV() {
        if let engine = self.engine {
            engine.disconnectNodeInput(self)
            for (_, connection) in connections.enumerated() {
                connection.disconnectAV()
            }
        }
    }

    /// Work-around for an AVAudioEngine bug.
    func initLastRenderTime() {
        // We don't have a valid lastRenderTime until we query it.
        _ = self.lastRenderTime

        for connection in connections {
            connection.initLastRenderTime()
        }
    }

    /// Scan for all parameters and associate with the node.
    /// - Parameter node: AVAudioNode to associate
    func associateParams(with node: AVAudioNode) {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if let param = child.value as? ParameterBase {
                param.projectedValue.associate(with: node)
            }
        }
    }

    func makeAVConnections() {
        if let node = self as? HasInternalConnections {
            node.makeInternalConnections()
        }

        // Are we attached?
        if let engine = self.engine {
            for (bus, connection) in connections.enumerated() {
                if let sourceEngine = connection.self.engine {
                    if sourceEngine != self.engine {
                        Log("🛑 Error: Attempt to connect nodes from different engines.")
                        return
                    }
                }

                engine.attach(connection.self)

                // Mixers will decide which input bus to use.
                if let mixer = self as? AVAudioMixerNode {
                    mixer.connectMixer(input: connection.self)
                } else {
                    self.connect(input: connection.self, bus: bus)
                }

                connection.makeAVConnections()
            }
        }
    }

    var bypassed: Bool {
        get { self.auAudioUnit.shouldBypassEffect }
        set { self.auAudioUnit.shouldBypassEffect = newValue }
    }
}

public protocol HasInternalConnections: AnyObject {
    /// Override point for any connections internal to the node.
    func makeInternalConnections()
}

/// Protocol mostly to support DynamicOscillator in SoundpipeAudioKit, but could be used elsewhere
public protocol DynamicWaveformNode: Node {
    /// Sets the wavetable
    /// - Parameter waveform: The tablve
    func setWaveform(_ waveform: Table)

    /// Gets the floating point values stored in the wavetable
    func getWaveformValues() -> [Float]
    
    /// Set the waveform change handler
    /// - Parameter handler: Closure with an array of floats as the argument
    func setWaveformUpdateHandler(_ handler: @escaping ([Float]) -> Void)
}
