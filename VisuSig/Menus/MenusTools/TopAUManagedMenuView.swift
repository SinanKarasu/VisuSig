//
//  ContentView.swift
//  RetroDock
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI

struct TopAUManagedMenuView: View {
    // Used to refresh the view periodically
    @State var refresh = false

    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents

    @State var loaded = false

    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }


    var body: some View {
        ScrollView([.horizontal]) {
            HStack(alignment: .bottom, spacing: 70) {
                ForEach(audioUnitComponents.auManagedEffectUnits, id: \.self) { item in
                    Button {
                        // guard let url = URL(string: item) else { return }
                        // NSWorkspace.shared.open(url)
                    } label: {
                        componentIcon5(auManagedUnit: item!)
                    }.buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: 100, maxHeight: 100)

                    // componentIcon5(auManagedUnit: item!)
                }.opacity(refresh ? 1 : 1)
            }
        }
    }

//    func componentIcon2(auManagedUnit: AUManagedUnit) -> Image? {
//        guard let icon = auManagedUnit.iconOld
//        else { return nil }
//        //let nsImage = NSImage(cgImage: icon, size: CGSize(width: icon.width, height: icon.height))
//        return Image(nsImage: icon)
//    }
// 
//    func componentIcon3(auManagedUnit: AUManagedUnit) -> Image? {
//        guard let icon = auManagedUnit.icon
//        else { return nil }
//        //let nsImage = NSImage(cgImage: icon, size: CGSize(width: icon.width, height: icon.height))
//        return Image(nsImage: icon)
//    }
//
//    func componentIcon4(auManagedUnit: AUManagedUnit) -> Image? {
//        guard let icon = auManagedUnit.protoType?.avAudioUnitComponent?.iconURL
//        else { return nil }
//        //let nsImage = NSImage(cgImage: icon, size: CGSize(width: icon.width, height: icon.height))
//        return Image(nsImage: NSImage(byReferencing:icon))
//    }

    func componentIcon5(auManagedUnit: AUManagedUnit) -> some View {
        return ZStack {
            Image(systemName: "waveform.and.mic")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
            Text(auManagedUnit.name)
        }
    }
}


struct LeftMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopAUManagedMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
