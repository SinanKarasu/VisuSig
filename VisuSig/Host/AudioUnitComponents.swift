//
//  AudioUnitComponents.swift
//  VisuSig
//
//  Created by Sinan Karasu on 3/13/21.
//

import SwiftUI
import AVFoundation
import CoreAudioKit
import os

let logger = Logger()

@Observable
class AudioUnitComponents {
    private var options = AudioComponentInstantiationOptions.loadOutOfProcess

    var audioUnitComponents = [Component]()
    var instrumentComponents = [Component]()

    var audioUnitManager = AudioUnitManager()
    var auManagedEffectUnits = [AUManagedUnit?]()
    var auManagedInstruments = [AUManagedUnit?]()

    private var effectsInitialized = false
    private var instsInitialized = false

    init() {
        startRunning()
    }

    func initializeEffects(instantiate: Bool = true) {
        guard !effectsInitialized else { return }
        effectsInitialized = true
        DispatchQueue.main.async {
            self.loadAudioUnits(ofType: .effect, instantiate: instantiate)
        }
    }

    func initializeInstruments(instantiate: Bool = true) {
        guard !instsInitialized else { return }
        instsInitialized = true
        DispatchQueue.main.async {
            self.loadAudioUnits(ofType: .instrument, instantiate: instantiate)
        }
    }

    func loadAudioUnits(ofType type: AudioUnitType, instantiate: Bool = true) {
        audioUnitManager.loadAudioUnits(ofType: type) { audioUnits in
            switch type {
            case .effect:    self.audioUnitComponents = audioUnits
            case .instrument: self.instrumentComponents = audioUnits
            }
            DispatchQueue.global(qos: .default).async {
                self.instantiateAllComponents(ofType: type)
            }
        }
    }

    func instantiateAllComponents(ofType type: AudioUnitType) {
        var auManaged = [AUManagedUnit?]()
        let components: [Component]
        switch type {
        case .effect:    components = audioUnitComponents
        case .instrument: components = instrumentComponents
        }
        for index in 0 ..< components.count {
            DispatchQueue.main.async {
                components[index].instantiateComponent { result in
                    switch result {
                    case .success(let au):
                        auManaged.append(au)
                        switch type {
                        case .effect:    self.auManagedEffectUnits = auManaged
                        case .instrument: self.auManagedInstruments = auManaged
                        }
                    case .failure(let error):
                        logger.log("Unable to instantiate audio unit: \(String(describing: error))")
                    }
                }
            }
        }
    }

    private func startRunning() {
        initializeEffects()
    }

    func connectComponent(auManagedUnit: AUManagedUnit?, completion: @escaping (Result<AUManagedUnit?, Error>) -> Void) {
        let avAudioUnit = auManagedUnit?.avAudioUnit
        audioUnitManager.playEngine.connect(avAudioUnit: avAudioUnit) {
            DispatchQueue.main.async {
                completion(.success(auManagedUnit))
            }
        }
    }

    func descAU(desc: AudioComponentDescription) -> String {
        let x = stringFrom4B(desc.componentType) ?? "????"
        let y = stringFrom4B(desc.componentSubType) ?? "????"
        let z = stringFrom4B(desc.componentManufacturer) ?? "????"
        return "comp:" + x + " sub:" + y + " mfg:" + z
    }

    func stringFrom4B(_ xx: UInt32) -> String? {
        return String(data: Data(byteArray(from: xx)), encoding: .utf8)
    }

    func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
}
