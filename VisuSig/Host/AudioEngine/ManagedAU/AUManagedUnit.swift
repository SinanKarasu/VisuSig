//
//  AUManagedUnit.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/1/22.
//

import CoreAudioKit

import AVFoundation


class AUManagedUnit: ObservableObject, Identifiable, Hashable {
    static func == (lhs: AUManagedUnit, rhs: AUManagedUnit) -> Bool {
        lhs.id == rhs.id
    }
    
    
    let id = UUID()
    var protoType: AVAudioUnitComponent?
    var observer: NSKeyValueObservation?
    //let name = "Sinan"
    var userPresetChangeType: UserPresetsChangeType = .undefined
    
    private var currentViewConfigurationIndex = 1
    
    let componentViewController = ComponentViewController()
    var iconOld: NSImage? = nil
    
    var icon: NSImage? {
        get {
            protoType?.icon
        }
    }
    
    var nsViewController: NSViewController? = nil
    let audiioUnitType: AudioUnitType
    
    public var name: String {
        guard let component = protoType else {
            //return audioUnitType == .effect ? "(No Effect)" : "(No Instrument)"
            return "No Name"
        }
        return "\(component.name) (\(component.manufacturerName))"
    }

    public var hasCustomView: Bool {
        return protoType?.hasCustomView ?? false
    }

    func setController(controller: NSViewController?) {
        if nsViewController == nil {
            nsViewController = controller
        }
        // OK, it seems presentUserInterface actually means presentUserInterface
        componentViewController.presentUserInterface(nsViewController?.view)
        
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    func loadAudioUnitViewController(completion: @escaping (NSViewController?) -> Void) {
        if let audioUnit = audioUnit {
            audioUnit.requestViewController { viewController in
                DispatchQueue.main.async {
                    completion(viewController)
                }
            }
            
        } else {
            completion(nil)
        }
    }
    
    var audioUnit: AUAudioUnit? {
        get {
            avAudioUnit?.auAudioUnit
        }
    }
    
    var avAudioUnit: AVAudioUnit? {
        didSet {
            // A new audio unit was selected. Reset our internal state.
            observer = nil
            userPresetChangeType = .undefined
            
            // If the selected audio unit doesn't support user presets, return.
            guard audioUnit?.supportsUserPresets ?? false else { return }
            
            // Start observing the selected audio unit's "userPresets" property.
            observer = audioUnit?.observe(\.userPresets) { _, _ in
                DispatchQueue.main.async {
                    var changeType = self.userPresetChangeType
                    // If the change wasn't triggered by a user save or delete, it changed
                    // due to an external add or remove from the presets folder.
                    if ![.save, .delete].contains(changeType) {
                        changeType = .external
                    }
                    
                    // Post a notification to any registered listeners.
                    let change = UserPresetsChange(type: changeType, userPresets: self.userPresets)
                    NotificationCenter.default.post(name: .userPresetsChanged, object: change)
                    
                    // Reset property to its default value
                    self.userPresetChangeType = .undefined
                }
            }
        }
    }
    
    init(protoType: AVAudioUnitComponent?, audioUnit: AVAudioUnit?, audioUnitType: AudioUnitType, icon: NSImage?) {
        self.protoType = protoType
        self.avAudioUnit = audioUnit
        self.audiioUnitType = audioUnitType
        self.iconOld = icon
    }
    /// Determines if the selected AU provides more than one user interface.
    var providesAlterativeViews: Bool {
        guard let audioUnit = audioUnit else { return false }
        let supportedConfigurations = audioUnit.supportedViewConfigurations(viewConfigurations)
        return supportedConfigurations.count > 1
    }
    
    /// Determines if the selected AU provides provides user interface.
    var providesUserInterface: Bool {
        return audioUnit?.providesUserInterface ?? false
    }
    
    /// Toggles the current view mode (compact or expanded)
    func toggleViewMode() {
        guard let audioUnit = audioUnit else { return }
        currentViewConfigurationIndex = currentViewConfigurationIndex == 0 ? 1 : 0
        audioUnit.select(viewConfigurations[currentViewConfigurationIndex])
    }
    
    public var factoryPresets: [Preset] {
        guard let presets = audioUnit?.factoryPresets else { return [] }
        return presets.map { Preset(preset: $0) }
    }
    
    /// Get or set the audio unit's current preset.
    public var currentPreset: Preset? {
        get {
            guard let preset = audioUnit?.currentPreset else { return nil }
            return Preset(preset: preset)
        }
        set {
            audioUnit?.currentPreset = newValue?.audioUnitPreset
        }
    }
    
    // MARK: Preset Management
    /// Gets the audio unit's factory presets.
    
    // MARK: User Presets
    
    /// Gets the audio unit's user presets.
    public var userPresets: [Preset] {
        guard let presets = audioUnit?.userPresets else { return [] }
        return presets.map { Preset(preset: $0) }.reversed()
    }
    
    public func savePreset(_ preset: Preset) throws {
        userPresetChangeType = .save
        try audioUnit?.saveUserPreset(preset.audioUnitPreset)
    }
    
    public func deletePreset(_ preset: Preset) throws {
        userPresetChangeType = .delete
        try audioUnit?.deleteUserPreset(preset.audioUnitPreset)
    }
    
    var supportsUserPresets: Bool {
        return audioUnit?.supportsUserPresets ?? false
    }
    
    
    /// View configurations supported by the host app
    private var viewConfigurations: [AUAudioUnitViewConfiguration] = {
        let compact = AUAudioUnitViewConfiguration(width: 400, height: 100, hostHasController: false)
        let expanded = AUAudioUnitViewConfiguration(width: 800, height: 500, hostHasController: false)
        return [compact, expanded]
    }()
    
}
