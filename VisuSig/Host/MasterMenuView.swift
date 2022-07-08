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
    
    @StateObject var mesh: Mesh = Mesh.sampleMesh()

    
    
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
            //HStack {
            //TopAUManagedMenuView(audioUnitComponents: audioUnitComponents)
            TopComponentMenuView(audioUnitComponents: audioUnitComponents)
            SurfaceView(mesh: mesh, audioUnitComponents: audioUnitComponents)
            //EffectsToolsView()

            switch audioUnitType {
            case .effect:
                EffectsMenuView(audioUnitComponents: audioUnitComponents)
            case .instrument:
                InstrumentsMenuView(audioUnitComponents: audioUnitComponents)
            }
            //}
            //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        }
    }
}

struct MasterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MasterMenuView()
    }
}
