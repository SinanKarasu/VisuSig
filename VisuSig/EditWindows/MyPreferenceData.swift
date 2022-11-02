//
//  MyPreferenceData.swift
//  MyPreferenceData
//
//  Created by Sinan Karasu on 10/12/21.
//

import SwiftUI


struct MyPreferenceData: Identifiable {
    let id = UUID() // required when using ForEach later
    let vtype: MyViewType
    let bounds: Anchor<CGRect>

    // Calculate the color to use in the minimap, for each view type
    func getColor() -> Color {
        switch vtype {
        case .field(let length):
            return length == 0 ? .red : (length < 3 ? .yellow : .green)
        case .title:
            return .purple
        default:
            return .cyan
        }
    }

    // Returns true, if this view type must be shown in the minimap.
    // Only fields, field containers and the title are shown in the minimap
    func show() -> Bool {
        switch vtype {
        case .field:
            return true
        case .title:
            return true
        case .fieldContainer:
            return true
        default:
            return false
        }
    }
}
