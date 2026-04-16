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
    var audioUnitComponents = [Component]()

    var audioUnitManager = AudioUnitManager()
    var auManagedEffectUnits = [AUManagedUnit?]()

    private var effectsInitialized = false
    private(set) var previewAudioFileName = "No audio loaded"
    var hasPreviewAudioFile: Bool { audioUnitManager.hasLoadedPlaybackFile }

    init() {
        startRunning()
    }

    func initializeEffects() {
        guard !effectsInitialized else { return }
        effectsInitialized = true
        DispatchQueue.main.async {
            self.loadAudioUnits(ofType: .effect)
        }
    }

    func loadAudioUnits(ofType type: AudioUnitType) {
        audioUnitManager.loadAudioUnits(ofType: type) { audioUnits in
            self.audioUnitComponents = audioUnits
            DispatchQueue.global(qos: .default).async {
                self.instantiateAllComponents()
            }
        }
    }

    func instantiateAllComponents() {
        var auManaged = [AUManagedUnit?]()
        let components = audioUnitComponents
        for index in 0 ..< components.count {
            DispatchQueue.main.async {
                components[index].instantiateComponent { result in
                    switch result {
                    case .success(let au):
                        auManaged.append(au)
                        self.auManagedEffectUnits = auManaged
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

    func setPreviewAudioFile(url: URL) {
        previewAudioFileName = url.lastPathComponent
        audioUnitManager.loadPlaybackFile(url: url)
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
