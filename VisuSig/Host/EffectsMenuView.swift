//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct EffectsMenuView: View {
    private  let audioUnitType = AudioUnitType.effect
    @ObservedObject var audioUnitComponents: AudioUnitComponents
        
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
                    NavigationView {
                        ZStack { // note this is a bug fix workaround for XCode 14 beta. Remove it when fixed

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
            }
            .onAppear(perform: startRunning)
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
