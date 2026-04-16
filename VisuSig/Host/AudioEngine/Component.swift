//
//  Component.swift
//  VisuSig
//
//  Created by Sinan Karasu on 4/30/22.
//

import SwiftUI
import AVFoundation

extension AudioUnitType: Identifiable {
    var id: RawValue { rawValue }
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
    public var number: Int { audioUnitPreset.number }
    public var name: String { audioUnitPreset.name }
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

    public var name: String {
        guard let component = avAudioUnitComponent else {
            return audioUnitType == .effect ? "(No Effect)" : "(No Instrument)"
        }
        return component.name
    }

    public var mfg: String {
        avAudioUnitComponent?.manufacturerName ?? "(No mfg)"
    }

    public var hasCustomView: Bool {
        avAudioUnitComponent?.hasCustomView ?? false
    }
}

extension Component {
    var icon: Image {
        if let x = avAudioUnitComponent?.icon {
            return Image(nsImage: x)
        }
        return Image(systemName: "waveform.and.mic")
    }

    var componentIcon: some View {
        ZStack {
            Text(nameAndMFG)
                .foregroundColor(.white)
                .font(.system(size: 12))
        }
    }

    public var nameAndMFG: String { "\(name) (\(mfg))" }
}

extension Component: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Component {
    func instantiateComponent(completion: @escaping (Result<AUManagedUnit?, Error>) -> Void) {
        guard let avAudioUnitComponent = avAudioUnitComponent else {
            completion(.success(nil))
            return
        }
        let description = avAudioUnitComponent.audioComponentDescription
        AVAudioUnit.instantiate(with: description, options: options) { avAudioUnit, error in
            guard error == nil else {
                DispatchQueue.main.async { completion(.failure(error!)) }
                return
            }
            DispatchQueue.main.async {
                let nsImage = AudioComponentCopyIcon(avAudioUnitComponent.audioComponent)
                let unit = AUManagedUnit(protoType: self, audioUnit: avAudioUnit,
                                        audioUnitType: self.audioUnitType, icon: nsImage)
                completion(.success(unit))
            }
        }
    }
}
