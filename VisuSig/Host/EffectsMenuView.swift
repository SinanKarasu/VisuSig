//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct EffectsMenuView: View {
    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    
    @State var loaded: Bool = false
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }
    
    let audioUnitTypes: [AudioUnitType] = [ .effect, .instrument]
    var body: some View {
        startRunning()
        return GeometryReader { reader in
            VStack {
                HStack {
                    Text("EffectsMenuView")
                    Text("Count: \(audioUnitComponents.audioUnitComponents.count)")
                }
                NavigationView {
                    List {
                        ForEach(0..<audioUnitComponents.auManagedEffectUnits.count, id: \.self) { index in
                            NavigationLink(
                                destination:
                                    makeView5(index: index)
                            )
                            {
                                Label(audioUnitComponents.auManagedEffectUnits[index]!.name, systemImage: "waveform.circle")
                            }
                        }
                    }
                    .navigationTitle("Menu")
                }
            }
            //.onAppear(perform: startRunning)
        }
    }
    
    
    func makeView5(index: Int) -> some View {
        let auManagedUnit = audioUnitComponents.auManagedEffectUnits[index]
        auManagedUnit!.loadAudioUnitViewController() { nsViewController in
            auManagedUnit!.setController(controller: nsViewController)
            
        }
        
        return AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents)
    }
    
    func startRunning() {
        audioUnitComponents.initializeEffects()
//        if !audioUnitComponents.effectsInitialized{
//            audioUnitComponents.effectsInitialized = true
//            audioUnitComponents.loadAudioUnits(ofType: audioUnitType)
//        }
    }
    
}

struct EffectsMenuView_Preview: PreviewProvider {
    @StateObject var audioUnitComponents = AudioUnitComponents()

    static var previews: some View {
        EffectsMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
