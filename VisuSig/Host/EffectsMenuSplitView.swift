//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct EffectsMenuSplitView: View {
    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedIndex: Int?
    
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }
    
    let audioUnitTypes: [AudioUnitType] = [ .effect, .instrument]
    var body: some View {
        //startRunning()
        return GeometryReader { reader in
            VStack {
                VStack {
                    Text("EffectsMenuView")
                    Text("Effects Count: \(audioUnitComponents.audioUnitComponents.count)")
                    Text("Managed Count: \(audioUnitComponents.auManagedEffectUnits.count)")
                    
                }
                NavigationSplitView (columnVisibility: $columnVisibility) {
                    ZStack { // note this is a bug fix workaround for XCode 14 beta. Remove it when fixed
                        List(selection: $selectedIndex) {
                            ForEach(0..<audioUnitComponents.auManagedEffectUnits.count, id: \.self) { index in
                                Label(audioUnitComponents.auManagedEffectUnits[index]!.name, systemImage: "waveform.circle")
                            }
                        }
                    }
                    .navigationTitle("Menu")
                    
                } detail: {
                    makeView5(index: selectedIndex ?? 0)
                }
                
            }
            .onAppear(perform: startRunning)
        }
    }
    
    
    func makeView5(index: Int) -> some View {
        if index != 0 {
            let auManagedUnit = audioUnitComponents.auManagedEffectUnits[index]
            auManagedUnit!.loadAudioUnitViewController() { nsViewController in
                auManagedUnit!.setController(controller: nsViewController)
            }
            return AnyView(AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents))
        }
        return AnyView(EmptyView())
    }
    
    
    func startRunning() {
        audioUnitComponents.initializeEffects()
        //        if !audioUnitComponents.effectsInitialized{
        //            audioUnitComponents.effectsInitialized = true
        //            audioUnitComponents.loadAudioUnits(ofType: audioUnitType)
        //        }
    }
    
}

struct EffectsMenuSplitView_Preview: PreviewProvider {
    @StateObject var audioUnitComponents = AudioUnitComponents()
    
    static var previews: some View {
        EffectsMenuSplitView(audioUnitComponents: AudioUnitComponents())
    }
}
