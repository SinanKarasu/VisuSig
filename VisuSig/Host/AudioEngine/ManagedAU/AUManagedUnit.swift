//
//  AUManagedUnit.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/1/22.
//

import CoreAudioKit
import AVFoundation
import SwiftUI

class AUManagedUnit: Identifiable, Hashable {

    static func == (lhs: AUManagedUnit, rhs: AUManagedUnit) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id = UUID()
    var protoType: Component?
    var observer: NSKeyValueObservation?
    var userPresetChangeType: UserPresetsChangeType = .undefined

    private var currentViewConfigurationIndex = 1

    let componentViewController = ComponentViewController()
    var iconOld: NSImage?
    var nsViewController: NSViewController?

    let audioUnitType: AudioUnitType

    // MARK: - Identity

    public var name: String {
        guard let component = protoType else {
            return audioUnitType == .effect ? "(No Effect)" : "(No Instrument)"
        }
        return "\(component.name) (\(component.avAudioUnitComponent?.manufacturerName ?? "Unknown"))"
    }

    public var hasCustomView: Bool {
        protoType?.hasCustomView ?? false
    }

    // MARK: - Init

    init(protoType: Component?, audioUnit: AVAudioUnit?, audioUnitType: AudioUnitType, icon: NSImage?) {
        self.protoType = protoType
        self.avAudioUnit = audioUnit
        self.audioUnitType = audioUnitType
        self.iconOld = icon
    }

    // MARK: - AU View Controller

    func loadAudioUnitViewController(completion: @escaping (NSViewController?) -> Void) {
        guard let audioUnit = audioUnit else { completion(nil); return }
        audioUnit.requestViewController { viewController in
            DispatchQueue.main.async { completion(viewController) }
        }
    }

    func setController(controller: NSViewController?) {
        if nsViewController == nil {
            nsViewController = controller
        }
        componentViewController.presentUserInterface(nsViewController?.view)
    }

    // MARK: - Audio Unit

    var audioUnit: AUAudioUnit? { avAudioUnit?.auAudioUnit }

    var avAudioUnit: AVAudioUnit? {
        didSet {
            observer = nil
            userPresetChangeType = .undefined

            guard audioUnit?.supportsUserPresets ?? false else { return }

            observer = audioUnit?.observe(\.userPresets) { _, _ in
                DispatchQueue.main.async {
                    var changeType = self.userPresetChangeType
                    if ![.save, .delete].contains(changeType) {
                        changeType = .external
                    }
                    let change = UserPresetsChange(type: changeType, userPresets: self.userPresets)
                    NotificationCenter.default.post(name: .userPresetsChanged, object: change)
                    self.userPresetChangeType = .undefined
                }
            }
        }
    }

    // MARK: - View configuration

    var providesAlterativeViews: Bool {
        guard let audioUnit else { return false }
        return audioUnit.supportedViewConfigurations(viewConfigurations).count > 1
    }

    var providesUserInterface: Bool {
        audioUnit?.providesUserInterface ?? false
    }

    func toggleViewMode() {
        guard let audioUnit else { return }
        currentViewConfigurationIndex = currentViewConfigurationIndex == 0 ? 1 : 0
        audioUnit.select(viewConfigurations[currentViewConfigurationIndex])
    }

    private var viewConfigurations: [AUAudioUnitViewConfiguration] = {
        let compact  = AUAudioUnitViewConfiguration(width: 400, height: 100, hostHasController: false)
        let expanded = AUAudioUnitViewConfiguration(width: 800, height: 500, hostHasController: false)
        return [compact, expanded]
    }()

    // MARK: - Presets

    public var factoryPresets: [Preset] {
        (audioUnit?.factoryPresets ?? []).map { Preset(preset: $0) }
    }

    public var userPresets: [Preset] {
        (audioUnit?.userPresets ?? []).map { Preset(preset: $0) }.reversed()
    }

    public var currentPreset: Preset? {
        get { audioUnit?.currentPreset.map { Preset(preset: $0) } }
        set { audioUnit?.currentPreset = newValue?.audioUnitPreset }
    }

    var supportsUserPresets: Bool { audioUnit?.supportsUserPresets ?? false }

    public func savePreset(_ preset: Preset) throws {
        userPresetChangeType = .save
        try audioUnit?.saveUserPreset(preset.audioUnitPreset)
    }

    public func deletePreset(_ preset: Preset) throws {
        userPresetChangeType = .delete
        try audioUnit?.deleteUserPreset(preset.audioUnitPreset)
    }
}
