//
//  MasterMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/8/22.
//

import SwiftUI

struct MasterMenuView: View {
    
    @StateObject var audioUnitComponents = AudioUnitComponents()
    @State private  var audioUnitType = AudioUnitType.effect
    @State var loaded: Bool = false
    
    
    
    var body: some View {
        VStack {
            SiKPlayerView(audioUnitManager: audioUnitComponents.audioUnitManager)
            Picker("Module Type:", selection: $audioUnitType) {
                Text("Effect").tag(AudioUnitType.effect)
                Text("Instrument").tag(AudioUnitType.instrument)
            }
            
            .pickerStyle(.segmented)
            .onChange(of: audioUnitType) { tag in
                //            self.loaded = false
                //            self.startRunning()
            }
            
            switch audioUnitType {
            case .effect:
                EffectsMenuView(audioUnitComponents: audioUnitComponents)
            case .instrument:
                InstrumMenuView(audioUnitComponents: audioUnitComponents)
            }
            //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

struct MasterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MasterMenuView()
    }
}
