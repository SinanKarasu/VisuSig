//
//  MyContentView.swift
//  MyContentView
//
//  Created by Sinan Karasu on 10/12/21.
//

import SwiftUI


struct MyContentView: View {
    @State private var fieldValues = [String](repeating: "", count: 5)
    @State private var length: Float = 360
    @State private var twitterFieldPreset = false

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .center) {
                // This view puts a gray rectangle where the minimap elements will be.
                // We will reference its size and position later, to make sure the mini map elements
                // are overlayed right on top of it.
                Color(red: 0.7, green: 0.2, blue: 0.3)
                    .frame(width: 300)
                    .anchorPreference(key: MyPreferenceKey.self, value: .bounds) {
                        return [MyPreferenceData(vtype: .miniMapArea, bounds: $0)]
                    }
                    .padding(.horizontal, 30)

                VStack(alignment: .leading) {
                    // Title
                    VStack {
                        Text("Hello \(fieldValues[0]) \(fieldValues[1]) \(fieldValues[2])")
                            .font(.title).fontWeight(.bold)
                            .anchorPreference(key: MyPreferenceKey.self, value: .bounds) {
                                return [MyPreferenceData.init(vtype: .title, bounds: $0)]
                            }
                        Divider()
                    }

                    // Switch + Slider
                    HStack {
                        Toggle(isOn: $twitterFieldPreset) { Text("") }

                        Slider(value: $length, in: 360...540).layoutPriority(1)
                    }.padding(.bottom, 5)

                    // First row of text fields
                    HStack {
                        MyFormField(fieldValue: $fieldValues[0], label: "First Name")
                        MyFormField(fieldValue: $fieldValues[1], label: "Middle Name")
                        MyFormField(fieldValue: $fieldValues[2], label: "Last Name")
                    }.frame(width: 540)

                    // Second row of text fields
                    HStack {
                        MyFormField(fieldValue: $fieldValues[3], label: "Email")

                        if twitterFieldPreset {
                            MyFormField(fieldValue: $fieldValues[4], label: "Twitter")
                        }
                    }.frame(width: CGFloat(length))
                }.transformAnchorPreference(key: MyPreferenceKey.self, value: .bounds) {
                    $0.append(MyPreferenceData(vtype: .formContainer, bounds: $1))
                }

                Spacer()
            }
            .overlayPreferenceValue(MyPreferenceKey.self) { preferences in
                GeometryReader { geometry in
                    MiniMap(geometry: geometry, preferences: preferences)
                }
            }

            Spacer()
        }.background(Color(red: 0.1, green: 0.2, blue: 0.5, opacity: 0.9)).edgesIgnoringSafeArea(.all)
    }
}
