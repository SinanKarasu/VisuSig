//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct InstrumentsMenuView: View {
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
                    Text("Components: \(audioUnitComponents.instrumentComponents.count)")
                    Text("Count: \(audioUnitComponents.auManagedInstruments.count)")

                }
                ZStack { // note this is a bug fix workaround for XCode 14 beta. Remove it when fixed
                    NavigationView {
                        List {
                            ForEach(0..<audioUnitComponents.auManagedInstruments.count, id: \.self) { index in
                                NavigationLink(
                                    destination:
                                        makeView5(index: index)
                                )
                                {
                                    Label(audioUnitComponents.auManagedInstruments[index]!.name, systemImage: "pianokeys.inverse")
                                }
                            }
                        }
                        .navigationTitle("Menu")
                    }
                }
            }
            //.onAppear(perform: startRunning)
        }
    }
        
    
    func makeView5(index: Int) -> some View {
        let auManagedUnit = audioUnitComponents.auManagedInstruments[index]
        auManagedUnit!.loadAudioUnitViewController() { nsViewController in
            auManagedUnit!.setController(controller: nsViewController)
        }
        
        return AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents)
    }
    
    func startRunning() {
        DispatchQueue.main.async {
            if !audioUnitComponents.instsInitialized {
                audioUnitComponents.instsInitialized = true
                audioUnitComponents.loadAudioUnits(ofType: audioUnitType)
        }
        }
    }
}

struct InstrumMenuView_Preview: PreviewProvider {
    static var previews: some View {
        InstrumentsMenuView(audioUnitComponents: AudioUnitComponents())
    }
}
