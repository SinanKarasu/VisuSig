//
//  DropDownMenu.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/24/22.
//

import SwiftUI


struct DropDownMenu: View {
    @State private var address: String = ""

    var uniqueKey: String {
        UUID().uuidString
    }



    var body: some View {
        let options: [DropdownOption] = [
            DropdownOption(key: uniqueKey, value: "Sunday"),
            DropdownOption(key: uniqueKey, value: "Monday"),
            DropdownOption(key: uniqueKey, value: "Tuesday"),
            DropdownOption(key: uniqueKey, value: "Wednesday"),
            DropdownOption(key: uniqueKey, value: "Thursday"),
            DropdownOption(key: uniqueKey, value: "Friday"),
            DropdownOption(key: uniqueKey, value: "Saturday")
        ]

        return VStack(spacing: 20) {
            DropdownSelector(
                placeholder: "Day of the week",
                options: options,
                onOptionSelected: { option in
                    print(option)
            })
            .padding(.horizontal)
            .zIndex(1)

            Group {
                TextField("Full Address", text: $address)
                    .font(.system(size: 14))
                    .padding(.horizontal)
            }
            .frame(width: .infinity, height: 450)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}
