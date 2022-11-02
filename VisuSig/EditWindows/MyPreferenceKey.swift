//
//  MyPreferenceKey.swift
//  MyPreferenceKey
//
//  Created by Sinan Karasu on 10/12/21.
//

import SwiftUI


struct MyPreferenceKey: PreferenceKey {
    typealias Value = [MyPreferenceData]

    static var defaultValue: [MyPreferenceData] = []

    static func reduce(value: inout [MyPreferenceData], nextValue: () -> [MyPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}
