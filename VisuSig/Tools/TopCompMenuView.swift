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
        HStack(alignment: .bottom, spacing: 70) {
            ForEach(audioUnitComponents.auManagedEffectUnits, id: \.self) { item in
                componentIcon2(auManagedUnit: item!)
            }.opacity(refresh ? 1 : 1)
        }
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
