//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct InstrumMenuView: View {
    private  let audioUnitType = AudioUnitType.instrument
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    
    @State var loaded: Bool = false
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }
    
    //let audioUnitTypes: [AudioUnitType] = [ .effect, .instrument]
    var body: some View {
        startRunning()
        return GeometryReader { reader in
            VStack {
                HStack {
                    Text("Instrument Menu View")
                    Text("Count: \(audioUnitComponents.instrumentComponents.count)")
                }
                NavigationView {
                    List {
                        ForEach(0..<audioUnitComponents.auManagedInstruments.count, id: \.self) { index in
                            NavigationLink(
                                destination:
                                makeView5(index: index)
                            )
                            {
                                Label(audioUnitComponents.instrumentComponents[index].name, systemImage: "pianokeys.inverse")
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
        let auManagedUnit = audioUnitComponents.auManagedInstruments[index]
        audioUnitComponents.loadAudioUnitViewController(auManagedUnit: auManagedUnit) { nsViewController in
            auManagedUnit!.setController(controller: nsViewController)
        }
        
        return AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitType: audioUnitType)
    }
    
    func startRunning() {
        DispatchQueue.main.async {
            if !audioUnitComponents.instsInitialized {

                audioUnitComponents.loadAudioUnits(ofType: audioUnitType)
                audioUnitComponents.instsInitialized = true
        }
        }
    }
    
    func loadAudioUnits(ofType type: AudioUnitType) {
        // Ensure audio playback is stopped before loading.
        //audioUnitManager.stopPlayback()
        // Load audio units.
        audioUnitManager.loadAudioUnits(ofType: type) {  audioUnits in
            switch type {
            case .effect:
                audioUnitComponents.audioUnitComponents = audioUnits
            case .instrument:
                audioUnitComponents.instrumentComponents = audioUnits
            }
            //audioUnitComponents.audioUnitComponents = audioUnits
            //DispatchQueue.main.async {
            DispatchQueue.global(qos: .default).async {
                audioUnitComponents.instantiateAllComponents(ofType: type)
            }
            loaded = true
        }
    }
}

struct InstrumMenuView_Preview: PreviewProvider {
    static var previews: some View {
        InstrumMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
