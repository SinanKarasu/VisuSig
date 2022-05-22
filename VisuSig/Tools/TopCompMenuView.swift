//
//  ContentView.swift
//  RetroDock
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI

struct TopCompMenuView: View {

    // Used to refresh the view periodically
    @State var refresh = false
    
    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    
    @State var loaded: Bool = false
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }


    var body: some View {
        VStack {
            Spacer()
                .frame(height: 20)

            // Front
            ZStack(alignment: .bottom) {

                // Icons
                HStack {
                    ForEach(items, id: \.self) { item in
                        Button {
                            guard let url = URL(string: item) else { return }
                            NSWorkspace.shared.open(url)
                        } label: {
                            componentIcon(forURL: item)?.resizable().aspectRatio(contentMode: .fit)
                        }.buttonStyle(PlainButtonStyle())

                    }
                }.frame(height: 75).offset(y: -15)

                // Reflections
                HStack {
                    ForEach(items, id: \.self) { item in
                        componentIcon(forURL: item)?.resizable().aspectRatio(contentMode: .fit)
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
    
    func componentIcon(forURL url: String) -> Image? {
        guard let icon =
                NSWorkspace.shared.icon(forFile: url.replacingOccurrences(of: "file://", with: ""))
                .representations
                .first(where: { $0.size.width > 150 })?
                .cgImage(forProposedRect: nil, context: nil, hints: nil)
            else { return nil }
        let nsImage = NSImage(cgImage: icon, size: CGSize(width: icon.width, height: icon.height))
        return Image(nsImage: nsImage)
    }

    func componentIcon2(auManagedUnit: AUManagedUnit) -> Image? {
        guard let icon = auManagedUnit.icon
            else { return nil }
        //let nsImage = NSImage(cgImage: icon, size: CGSize(width: icon.width, height: icon.height))
        return Image(nsImage: icon)
    }

}



struct LeftMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopCompMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
