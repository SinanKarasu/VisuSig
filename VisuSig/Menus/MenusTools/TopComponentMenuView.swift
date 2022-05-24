//
//  ContentView.swift
//  RetroDock
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI

struct TopComponentMenuView: View {
    
    // Used to refresh the view periodically
    @State var refresh = false
    
    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    
    @State var loaded: Bool = false
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }
    
    
    var body: some View {
        audioUnitComponents.initializeEffects(instantiate: false)
        return ScrollView([.horizontal]) {
            HStack(alignment: .bottom, spacing: 70) {
                

                ForEach(audioUnitComponents.audioUnitComponents, id: \.self) { item in
                    
                    Button {
                        //guard let url = URL(string: item) else { return }
                        //NSWorkspace.shared.open(url)
                    } label: {
                        componentIcon5(auManagedUnit: item)
                    }.buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: 100, maxHeight: 100)

                    //componentIcon5(auManagedUnit: item!)
                }.opacity(refresh ? 1 : 1)
                    
            }
        }
        
    }
    
    
    func componentIcon5(auManagedUnit: Component) -> some View {
        return ZStack {
            Image(systemName: "waveform.and.mic")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
            Text(auManagedUnit.nameAndMFG)
        }
    }
    
    
    
}



struct TopComponentMenuView_Previews: PreviewProvider {
    static var previews: some View {
        TopComponentMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
