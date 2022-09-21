//
//  MasterMenuView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 5/8/22.
//

import SwiftUI

struct MyBorder: View {
    let color: Color
    var body: some View {
        Rectangle()
            .stroke(color, lineWidth: 5)
    }
}

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
                GeometryReader { proxy in
                    VStack {
                        SiKPlayerView(audioUnitManager: audioUnitComponents.audioUnitManager)
                            .addBorder(.yellow)
                        //HStack {
                        //TopAUManagedMenuView(audioUnitComponents: audioUnitComponents) // probably delete this
                        //TopComponentMenuView(audioUnitComponents: audioUnitComponents)
                        SurfaceView(mesh: mesh, audioUnitComponents: audioUnitComponents)
                            .addBorder(.orange)
                        //EffectsToolsView()
                        //EffectsToolsView(audioUnitComponents: audioUnitComponents)
                        
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
                            EffectsMenuSplitView(audioUnitComponents: audioUnitComponents)
                                .addBorder(.blue)
                        case .instrument:
                            InstrumentsMenuSplitView(audioUnitComponents: audioUnitComponents)
                                .addBorder(.green)
                        }
                        //}
                        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                    }
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
