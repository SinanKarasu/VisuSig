//
//  AudioUnitType.swift
//  VisuSig
//
//  Created by Sinan Karasu on 8/4/22.
//

import Foundation

// An enum used to prevent exposing the Core Audio component description's componentType to the UI layer.
enum AudioUnitType: Int, CaseIterable, Codable {
    case effect
    case instrument
}
