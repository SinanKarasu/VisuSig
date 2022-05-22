//
//  ContentView.swift
//  RetroDock
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI

struct ToolMenu3View: View {

    // Used to refresh the view periodically
    @State var refresh = false

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 20)

            // Front
            ZStack(alignment: .bottom) {
//                RoundedRectangle(cornerRadius: 5)
//                    .fill(
//                        Color(red: 216/255, green: 216/255, blue: 216/255).opacity(0.9))
//                    .mask(
//                        VStack {
//                            //sik Spacer()
//                            Rectangle()
//                                .fill(Color.blue)
//                                .frame(height: 6).padding(.horizontal, 1.5)
//                        }
//                    )

                // Shelf
//                RoundedRectangle(cornerRadius: 5)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(
//                                colors: [Color(red: 155/255, green: 155/255, blue: 155/255).opacity(0.5), Color.white.opacity(0.85)]),
//                            startPoint: .top, endPoint: .bottom)
//                    )
//                    .frame(height: 85)
//                    .rotation3DEffect(
//                        Angle(degrees: 50),
//                        axis: (x: 1, y: 0, z: 0), anchor: .bottom
//                    )
//                    .offset(x: 0, y: -4)
//                    .shadow(color: .white, radius: 0, x: 0, y: 1)

                // Icons
                HStack {
                    ForEach(items, id: \.self) { item in
                        Button {
                            guard let url = URL(string: item) else { return }
                            NSWorkspace.shared.open(url)
                        } label: {
                            SystemIcon(forURL: item)?.resizable().aspectRatio(contentMode: .fit)
                        }.buttonStyle(PlainButtonStyle())

                    }
                }.frame(height: 75).offset(y: -15)

                // Reflections
                HStack {
                    ForEach(items, id: \.self) { item in
                        SystemIcon(forURL: item)?.resizable().aspectRatio(contentMode: .fit)
                    }
                }.frame(height: 75)
                .rotation3DEffect(
                    Angle(degrees: 180),
                    axis: (x: 1, y: 0, z: 0.0)
                )
                .offset(y: 57)
                .mask(
                    Rectangle()
                        .offset(y: -2)
                )
                .blur(radius: 4)
                .opacity(0.3)

                // Running indicators
                HStack(alignment: .bottom, spacing: 70) {
                    ForEach(items, id: \.self) { item in
                        if NSWorkspace.shared
                            .runningApplications
                            .first(where: { $0.bundleURL?.absoluteString.contains(item) ?? false }) != nil {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 13, height: 8)
                                .offset(y: 5)
                                .shadow(color: Color(red: 168/255, green: 238/255, blue: 1), radius: 7, x: 0, y: 0)
                        } else {
                            Spacer().frame(width: 13)
                        }
                    }.opacity(refresh ? 1 : 1)
                }
            }
        }.onAppear {
            _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                refresh.toggle()
            })
        }
    }
}



struct ToolMenu3View_Previews: PreviewProvider {
    static var previews: some View {
        ToolMenu3View()
    }
}
