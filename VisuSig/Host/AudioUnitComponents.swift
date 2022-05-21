//
//  AudioComponents.swift
//  SiKAUv3Host
//
//  Created by Sinan Karasu on 3/13/21.
//

import SwiftUI
import AVFoundation
import CoreAudioKit
import os

let logger = Logger()

class AudioUnitComponents:ObservableObject {
    
    private var options = AudioComponentInstantiationOptions.loadOutOfProcess
    
    var audioUnitComponents = [Component]()
    var instrumentComponents = [Component]()
    
    var audioUnitManager = AudioUnitManager()
    @Published var auManagedEffectUnits = [AUManagedUnit?]()
    @Published var auManagedInstruments = [AUManagedUnit?]()
    
    var effectsInitialized = false
    var instsInitialized = false
    
    
    //var emptyDict = [UUID: ComponentViewController]()
    
    func loadAudioUnits(ofType type: AudioUnitType) {
        // Ensure audio playback is stopped before loading.
        //audioUnitManager.stopPlayback()
        // Load audio units.
        audioUnitManager.loadAudioUnits(ofType: type) {  audioUnits in
            switch type {
            case .effect:
                self.audioUnitComponents = audioUnits
            case .instrument:
                self.instrumentComponents = audioUnits
            }
            //DispatchQueue.main.async {
            DispatchQueue.global(qos: .default).async {
                self.instantiateAllComponents(ofType: type)
            }
        }
    }
    
    
    func loadAudioUnitViewController(auManagedUnit: AUManagedUnit?, completion: @escaping (NSViewController?) -> Void) {
        if let auManagedUnit = auManagedUnit {
            if let audioUnit = auManagedUnit.audioUnit {
                audioUnit.requestViewController { viewController in
                    DispatchQueue.main.async {
                        completion(viewController)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func instantiateAllComponents(ofType type: AudioUnitType) {
        var auManaged = [AUManagedUnit?]()
        var components = [Component]()
        switch type {
        case .effect:
            components = audioUnitComponents
        case .instrument:
            components = instrumentComponents
        }
        for index in 0 ..< components.count {
            DispatchQueue.main.async {
                self.instantiateComponent(component: components[index]) { result in
                    switch result {
                    case .success(let au):
                        auManaged.append(au)
                        switch type {
                        case .effect:
                            self.auManagedEffectUnits = auManaged
                        case .instrument:
                            self.auManagedInstruments = auManaged
                        }
                    case .failure(let error):
                        logger.log("Unable to select audio unit: \(String(describing: error))")
                    }
                }
            }
        }
    }
    
    // MARK: Instantiate an Audio Unit
    func instantiateComponent(component: Component, completion: @escaping (Result<AUManagedUnit?, Error>) -> Void)  {
        
        // nil out existing component
        var auManagedUnit: AUManagedUnit? = nil
        
        // Get the wrapped AVAudioUnitComponent
        
        guard let avAudioUnitComponent = component.avAudioUnitComponent else {
            // Reset the engine to remove any configured audio units.
            //playEngine.reset()
            // Return success, but indicate an audio unit was not selected.
            // This occurrs when the user selects the (No Effect) row.
            completion(.success(nil))
            return
        }
        
        // Get the component description
        let description = avAudioUnitComponent.audioComponentDescription
        
        // Instantiate the audio unit and connect it the the play engine.
        AVAudioUnit.instantiate(with: description, options: options) { avAudioUnit, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(.failure(error!))
                }
                return
            }
            DispatchQueue.main.async {
                auManagedUnit = AUManagedUnit(audioUnit: avAudioUnit, audioUnitType: component.audioUnitType)
                completion(.success(auManagedUnit))
            }
        }
    }
    
    func connectComponent(auManagedUnit: AUManagedUnit?, completion: @escaping (Result<AUManagedUnit?, Error>) -> Void)  {
        
        // nil out existing component
        //        var auManagedUnit: AUManagedUnit? = nil
        //
        //        // Get the wrapped AVAudioUnitComponent
        //
        //        guard let component = component.avAudioUnitComponent else {
        //            // Reset the engine to remove any configured audio units.
        //            //playEngine.reset()
        //            // Return success, but indicate an audio unit was not selected.
        //            // This occurrs when the user selects the (No Effect) row.
        //            completion(.success(nil))
        //            return
        //        }
        //
        //        // Get the component description
        //        let description = component.audioComponentDescription
        //
        //        // Instantiate the audio unit and connect it the the play engine.
        //        AVAudioUnit.instantiate(with: description, options: options) { avAudioUnit, error in
        //            guard error == nil else {
        //                DispatchQueue.main.async {
        //                    completion(.failure(error!))
        //                }
        //                return
        //            }
        //            DispatchQueue.main.async {
        //                auManagedUnit = AUManagedUnit(audioUnit: avAudioUnit?.auAudioUnit)
        //                completion(.success(auManagedUnit))
        //            }
        //        }
        let avAudioUnit = auManagedUnit?.avAudioUnit
        let description = avAudioUnit?.audioComponentDescription
        if let desc = description {
            print("desc: \(descAU(desc: desc))")
        }
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
        let code = "comp:" + x
        + " sub:" + y
        + " mfg:" + z
        return code
    }
    
    
    func stringFrom4B(_ xx: UInt32) -> String? {
        return String(data: Data(byteArray(from: xx)), encoding: .utf8)
    }
    
    func byteArray<T>(from value: T) -> [UInt8] where T: FixedWidthInteger {
        withUnsafeBytes(of: value.bigEndian, Array.init)
    }
}
