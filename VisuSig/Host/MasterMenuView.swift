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
    
    @StateObject var mesh: Mesh = Mesh.sampleMesh()

    let mode = 2
    
    var body: some View {
        HStack {
            if mode == 1 {
                EmptyView() //MasterContentView() // This is the thre panel navigation
            } else {
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
                    //TopAUManagedMenuView(audioUnitComponents: audioUnitComponents) // probably delete this
                    //TopComponentMenuView(audioUnitComponents: audioUnitComponents)
                    SurfaceView(mesh: mesh, audioUnitComponents: audioUnitComponents)
                    //EffectsToolsView()
                    
                    switch audioUnitType {
                    case .effect:
                        EffectsMenuSplitView(audioUnitComponents: audioUnitComponents)
                    case .instrument:
                        InstrumentsMenuSplitView(audioUnitComponents: audioUnitComponents)
                    }
                    //}
                    //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                }
            }
        }
    }
}

struct MasterMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MasterMenuView()
    }
}
