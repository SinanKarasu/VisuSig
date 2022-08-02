//
//  Component.swift
//  VisuSig
//
//  Created by Sinan Karasu on 4/30/22.
//

import SwiftUI
import AVFoundation

// An enum used to prevent exposing the Core Audio component description's componentType to the UI layer.
enum AudioUnitType: Int, CaseIterable {
    case effect
    case instrument
}

extension AudioUnitType: Identifiable {
    var id: RawValue { rawValue }
}
// An enum used to prevent exposing the Core Audio AudioComponentInstantiationOptions to the UI layer.
enum InstantiationType: Int {
    case inProcess
    case outOfProcess
}

enum PresetType: Int {
    case factory
    case user
}

enum UserPresetsChangeType: Int {
    case save
    case delete
    case external
    case undefined
}

struct UserPresetsChange {
    let type: UserPresetsChangeType
    let userPresets: [Preset]
}

extension Notification.Name {
    static let userPresetsChanged = Notification.Name("userPresetsChanged")
}

// A simple wrapper type to prevent exposing the Core Audio AUAudioUnitPreset in the UI layer.
public struct Preset {
    init(name: String) {
        let preset = AUAudioUnitPreset()
        preset.name = name
        preset.number = -1
        self.init(preset: preset)
    }
    init(preset: AUAudioUnitPreset) {
        audioUnitPreset = preset
    }
    let audioUnitPreset: AUAudioUnitPreset
    public var number: Int { return audioUnitPreset.number }
    public var name: String { return audioUnitPreset.name }
}

public struct Component: Identifiable {
    

    public var id = UUID()
    
    let options = AudioComponentInstantiationOptions.loadOutOfProcess


    let audioUnitType: AudioUnitType
    let avAudioUnitComponent: AVAudioUnitComponent?

    init(_ component: AVAudioUnitComponent?, type: AudioUnitType) {
        audioUnitType = type
        avAudioUnitComponent = component
    }

}

// MARK: - identifiers for Tables etc..
extension Component {
    
    var icon: Image {
        get {
            if let x = avAudioUnitComponent?.icon {
                return Image(nsImage: x)
            }
            return Image(systemName:"waveform.and.mic")
        }
    }

    var componentIcon : some View {
        return ZStack {
            //icon
            Text(nameAndMFG)
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
        //.frame(width:100, height:100)
    }
    
    public var nameAndMFG: String {
        return "\(name) (\(mfg))"
    }
    
    public var name: String {
        guard let component = avAudioUnitComponent else {
            return audioUnitType == .effect ? "(No Effect)" : "(No Instrument)"
        }
        return "\(component.name)"
    }
    
    
    public var mfg: String {
        guard let component = avAudioUnitComponent else {
            return "(No mfg)"
        }
        return "\(component.manufacturerName)"
    }
    
    public var hasCustomView: Bool {
        return avAudioUnitComponent?.hasCustomView ?? false
    }

}

extension Component: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
extension Component {
    func instantiateComponent(completion: @escaping (Result<AUManagedUnit?, Error>) -> Void)  {
        
        // nil out existing component
        var auManagedUnit: AUManagedUnit? = nil
        
        // Get the wrapped AVAudioUnitComponent
        
        guard let avAudioUnitComponent = avAudioUnitComponent else {
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
                let nsImage = AudioComponentCopyIcon(avAudioUnitComponent.audioComponent)
                auManagedUnit = AUManagedUnit(protoType: self, audioUnit: avAudioUnit, audioUnitType: audioUnitType, icon: nsImage)
                completion(.success(auManagedUnit))
            }
        }
    }
}
