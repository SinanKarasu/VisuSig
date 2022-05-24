//
//  Component.swift
//  VisuSig
//
//  Created by Sinan Karasu on 4/30/22.
//

import SwiftUI
import AVFoundation

// An enum used to prevent exposing the Core Audio component description's componentType to the UI layer.
enum AudioUnitType: Int, CaseIterable, Identifiable {
    case effect
    case instrument
    var id: Int {self.rawValue}
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

public struct Component: Hashable, Identifiable {
    
    public var id = UUID()
    

    let audioUnitType: AudioUnitType
    let avAudioUnitComponent: AVAudioUnitComponent?

    init(_ component: AVAudioUnitComponent?, type: AudioUnitType) {
        audioUnitType = type
        avAudioUnitComponent = component
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

extension Component {
    var componentIcon : some View {
        return ZStack {
            Image(systemName: "waveform.and.mic")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
            Text(nameAndMFG)
        }
    }

}
