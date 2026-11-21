//
//  AudioUnitType.swift
//  VisuSig
//
//  Created by Sinan Karasu on 8/4/22.
//

import AudioToolbox
import Foundation

/// The Audio Unit kinds VisuSig hosts, named the way Logic groups them.
/// Keeps Core Audio's four-character component types out of the UI layer.
enum AudioUnitType: Int, CaseIterable, Codable {
    /// `aufx`: audio in, audio out.
    case effect
    /// `aumu`: MIDI in, audio out (a software instrument).
    case instrument
    /// `aumi`: MIDI in, MIDI out (arpeggiators, chord generators…).
    case midiEffect
    /// `aumf`: audio and MIDI in, audio out (an effect played from MIDI).
    case musicEffect

    var componentType: OSType {
        switch self {
        case .effect: return kAudioUnitType_Effect
        case .instrument: return kAudioUnitType_MusicDevice
        case .midiEffect: return kAudioUnitType_MIDIProcessor
        case .musicEffect: return kAudioUnitType_MusicEffect
        }
    }

    var singularName: String {
        switch self {
        case .effect: return "Audio Effect"
        case .instrument: return "Instrument"
        case .midiEffect: return "MIDI Effect"
        case .musicEffect: return "MIDI-Controlled Effect"
        }
    }

    var systemImage: String {
        switch self {
        case .effect: return "waveform.circle"
        case .instrument: return "pianokeys"
        case .midiEffect: return "music.note.list"
        case .musicEffect: return "waveform.badge.plus"
        }
    }

    var takesAudio: Bool { self == .effect || self == .musicEffect }
    var takesMIDI: Bool { self != .effect }
    var producesMIDI: Bool { self == .midiEffect }
    var producesAudio: Bool { self != .midiEffect }
}
