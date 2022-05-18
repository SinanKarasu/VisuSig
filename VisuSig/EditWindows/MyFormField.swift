//
//  MyFormField.swift
//  MyFormField
//
//  Created by Sinan Karasu on 10/12/21.
//

import SwiftUI

// This view draws a rounded box, with a label and a textfield
struct MyFormField: View {
    @Binding var fieldValue: String
    let label: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
            TextField("", text: $fieldValue)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .anchorPreference(key: MyPreferenceKey.self, value: .bounds) {
                    return [MyPreferenceData(vtype: .field(self.fieldValue.count), bounds: $0)]
                }
        }
        .padding(15)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color(red: 0.1, green: 0.7, blue: 0.5, opacity: 0.9)))
        .transformAnchorPreference(key: MyPreferenceKey.self, value: .bounds) {
            $0.append(MyPreferenceData(vtype: .fieldContainer, bounds: $1))
        }
    }
}
