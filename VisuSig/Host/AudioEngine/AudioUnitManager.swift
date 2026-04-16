/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The manager object used to find and instantiate audio units and manage their presets and view configurations.
 */

import Foundation
import CoreAudioKit
import AVFoundation

import AppKit
// public typealias NSViewController = NSViewController


// Manages the interaction with the AudioToolbox and AVFoundation frameworks.
@Observable
class AudioUnitManager {
    // Filter out these AUs. They don't make sense for this demo.
    var filterClosure: (AVAudioUnitComponent) -> Bool = {
        let blacklist = [String]() // ["AUNewPitch", "AURoundTripAAC", "AUNetSend"]
        var allowed = !blacklist.contains($0.name)
        if allowed && $0.typeName == AVAudioUnitTypeEffect {
            allowed = $0.hasCustomView
        }
        return allowed
    }

    /// The user-selected audio unit.
    var auManagedUnit: AUManagedUnit?

    /// The playback engine used to play audio.
    var playEngine = SimplePlayEngine()
    var hasLoadedPlaybackFile: Bool { playEngine.hasLoadedFile }
}


extension AudioUnitManager {
    // MARK: Load Audio Units

    func loadAudioUnits(ofType type: AudioUnitType, completion: @escaping ([Component]) -> Void) {
        // Reset the engine to remove any configured audio units.
        playEngine.reset()

        // Locating components is a blocking operation. Perform this work on a separate queue.
        DispatchQueue.global(qos: .default).async {
            let componentType = type == .effect ? kAudioUnitType_Effect : kAudioUnitType_MusicDevice

            // Make a component description matching any Audio Unit of the selected component type.
            let description = AudioComponentDescription(componentType: componentType,
                                                        componentSubType: 0,
                                                        componentManufacturer: 0,
                                                        componentFlags: 0,
                                                        componentFlagsMask: 0)

            let components = AVAudioUnitComponentManager.shared().components(matching: description)

            // Filter out components that don't make sense for this demo.
            // Map AVAudioUnitComponent to array of Component (view model) objects.
            let wrapped = components.filter(self.filterClosure).map { Component($0, type: type) }
            // let wrapped1 = components.map { Component($0, type: type) }

            // Insert a "No Effect" element into array if effect
//            if type == .effect {
//                wrapped.insert(Component(nil, type: type), at: 0)
//            }
            // Notify the caller of the loaded components.
            DispatchQueue.main.async {
                completion(wrapped)
                // completion(wrapped1)
            }
        }
    }
}


extension AudioUnitManager {
    // MARK: Audio Transport

    func loadPlaybackFile(url: URL) {
        playEngine.loadAudioFile(url)
    }

    @discardableResult
    func togglePlayback() -> Bool {
        return playEngine.togglePlay()
    }

    func stopPlayback() {
        playEngine.stopPlaying()
    }
}
