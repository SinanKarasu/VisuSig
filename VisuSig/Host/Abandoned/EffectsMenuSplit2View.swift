//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

// Now workie, and I know why...

import SwiftUI

struct EffectsMenuSplit2View: View {
    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedIndex: AUManagedUnit?
    
    
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
                    List(audioUnitComponents.auManagedEffectUnits, id: \.self, selection: $selectedIndex) { unit in
                        Label(unit!.name, systemImage: "waveform.circle")
                        
                    }
                    .navigationTitle("Menu")
                } detail: {
                    let _ = print("selected:\(makeName(selected: selectedIndex))")
                    makeView6(auManagedUnit: selectedIndex )
                        .id(selectedIndex)
                }
                
            }
            .onAppear(perform: startRunning)
        }
    }
    
    func makeName(selected: AUManagedUnit?) -> String {
        if let selected = selected {
            return selected.name
        }
        return "no name"
    }
    
    func makeView5(index: Int) -> some View {
        let _ = print("index:\(index)")
        
        if index != 0 {
            let auManagedUnit = audioUnitComponents.auManagedEffectUnits[index]
            let _ = print("Unit is:\(auManagedUnit!.name)")
            
            auManagedUnit!.loadAudioUnitViewController() { nsViewController in
                auManagedUnit!.setController(controller: nsViewController)
            }
            return AnyView(AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents))
        }
        return AnyView(Text("0 index"))
    }
    
    
    func makeView6(auManagedUnit: AUManagedUnit!) -> some View {
        guard auManagedUnit != nil  else {
            return AnyView(Text("0 index"))
        }
        
        let _ = print("Unit is:\(auManagedUnit!.name)")
        
        auManagedUnit!.loadAudioUnitViewController() { nsViewController in
            auManagedUnit!.setController(controller: nsViewController)
        }
        return AnyView(AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents))
    }
    
    
    
    func startRunning() {
        audioUnitComponents.initializeEffects()
        //        if !audioUnitComponents.effectsInitialized{
        //            audioUnitComponents.effectsInitialized = true
        //            audioUnitComponents.loadAudioUnits(ofType: audioUnitType)
        //        }
    }
    
}

struct EffectsMenuSplit2View_Preview: PreviewProvider {
    @StateObject var audioUnitComponents = AudioUnitComponents()
    
    static var previews: some View {
        EffectsMenuSplit2View(audioUnitComponents: AudioUnitComponents())
    }
}
