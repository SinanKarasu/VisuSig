//
//  AV+Extensions.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/26/22.
//

import AVFoundation

extension AVAudioMixerNode {
    /// Make a connection without breaking other connections.
    public func connectMixer(input: AVAudioNode, format: AVAudioFormat?) {
        if let engine = engine {
            var points = engine.outputConnectionPoints(for: input, outputBus: 0)
            if points.contains(where: { $0.node === self }) { return }
            points.append(AVAudioConnectionPoint(node: self, bus: nextAvailableInputBus))
            engine.connect(input, to: points, fromBus: 0, format: format)
        }
    }
}

// extension AVAudioNode {
//    var inputCount: Int { numberOfInputs }
//
//    func inputConnections() -> [AVAudioConnectionPoint] {
//        return (0 ..< inputCount).compactMap { engine?.inputConnectionPoint(for: self, inputBus: $0) }
//    }
// }


extension AVAudioNode {
    /// Disconnect without breaking other connections.
        func disconnect(input: AVAudioNode, format: AVAudioFormat? ) {
            if let engine = engine {
                var newConnections: [AVAudioNode: [AVAudioConnectionPoint]] = [:]
                for bus in 0 ..< numberOfInputs {
                    if let cp = engine.inputConnectionPoint(for: self, inputBus: bus) {
                        if cp.node === input {
                            let points = engine.outputConnectionPoints(for: input, outputBus: 0)
                            newConnections[input] = points.filter { $0.node != self }
                        }
                    }
                }

                for (node, connections) in newConnections {
                    if connections.isEmpty {
                        engine.disconnectNodeOutput(node)
                    } else {
                        engine.connect(node, to: connections, fromBus: 0, format: format)
                    }
                }
            }
        }

    /// Make a connection without breaking other connections.
    func connect(input: AVAudioNode, bus: Int, format: AVAudioFormat?) {
        if let engine = engine {
            var points = engine.outputConnectionPoints(for: input, outputBus: 0)
            if points.contains(where: {
                $0.node === self && $0.bus == bus
            }) { return }
            points.append(AVAudioConnectionPoint(node: self, bus: bus))
            engine.connect(input, to: points, fromBus: 0, format: format)
        }
    }
}
