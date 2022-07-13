//
//  AudioGraph.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/11/22.
//

import Foundation
import AVFoundation
import AudioToolbox


class AudioGraph: Mesh {
    let engine: AVAudioEngine = AVAudioEngine()
    private var _playerLoopBuffer: AVAudioPCMBuffer!

    func makeEngineConnections(edges: [EdgeBase]) {
        /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
         when this property is first accessed. You can then connect additional nodes to the mixer.
         
         By default, the mixer's output format (sample rate and channel count) will track the format
         of the output node. You may however make the connection explicitly with a different format. */
        
        // get the engine's optional singleton main mixer node
        let mainMixer = engine.mainMixerNode
        
        /*  Nodes have input and output buses (AVAudioNodeBus). Use connect:to:fromBus:toBus:format: to
         establish connections betweeen nodes. Connections are always one-to-one, never one-to-many or
         many-to-one.
         
         Note that any pre-existing connection(s) involving the source's output bus or the
         destination's input bus will be broken.
         
         @method connect:to:fromBus:toBus:format:
         @param node1 the source node
         @param node2 the destination node
         @param bus1 the output bus on the source node
         @param bus2 the input bus on the destination node
         @param format if non-null, the format of the source node's output bus is set to this
         format. In all cases, the format of the destination node's input bus is set to
         match that of the source node's output bus. */
        
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        let playerFormat = _playerLoopBuffer.format
        
        
        // establish a connection between nodes
        for edge in edges {
//            // connect the player to the reverb
//            // use the buffer format for the connection format as they must match
            engine.connect(edge.startPort.avAudioUnit!, to: edge.endPort.avAudioUnit!, format: playerFormat)
//
//            // connect the reverb effect to mixer input bus 0
//            // use the buffer format for the connection format as they must match
//            engine.connect(_reverb, to: mainMixer, fromBus: 0, toBus: 0, format: playerFormat)
//
//            // connect the distortion effect to mixer input bus 2
//            engine.connect(_distortion, to: mainMixer, fromBus: 0, toBus: 2, format: stereoFormat)
        }
//        // fan out the sampler to mixer input 1 and distortion effect
//        let destinationNodes = [
//            AVAudioConnectionPoint(node: engine.mainMixerNode, bus: 1),
//            AVAudioConnectionPoint(node: distortion, bus: 0)
//        ]
//        _engine.connect(_sampler, to: destinationNodes, fromBus: 0, format: stereoFormat)
    }
    
//    func myBuffer() {
//
//        // make a silent stereo buffer
//        var chLayout: AVAudioChannelLayout? = AVAudioChannelLayout(layoutTag:kAudioChannelLayoutTag_Stereo)
//        var chFormat: AVAudioFormat! = AVAudioFormat(
//            commonFormat: AVAudioCommonFormat.pcmFormatFloat32,
//            sampleRate:44100.0,
//            channels: AVAudioChannelCount(2),
//            interleaved: false
//        )
//        var avAudioPCMBuffer: AVAudioPCMBuffer! = AVAudioPCMBuffer(pcmFormat: chFormat, frameCapacity: 1024)
//
//        avAudioPCMBuffer.frameLength = avAudioPCMBuffer.frameCapacity;
//        for ch in 0..<chFormat.channelCount {
//
//        }
//    }

}
