//
//  EffectsMenuView.swift
//
//  Created by Sinan Karasu on 3/10/21.
//

import SwiftUI

struct InstrumentsMenuSplitView: View {
    private  let audioUnitType = AudioUnitType.instrument
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    @State var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var selectedIndex: Int?
    
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }
    
    //let audioUnitTypes: [AudioUnitType] = [ .effect, .instrument]
    var body: some View {
        //startRunning()
        return GeometryReader { reader in
            VStack {
                VStack {
                    Text("Instrument Menu View")
                    Text("Instrument Count: \(audioUnitComponents.instrumentComponents.count)")
                    Text("Managed Count: \(audioUnitComponents.auManagedInstruments.count)")
                    
                }
                NavigationSplitView (columnVisibility: $columnVisibility) {
                    List(selection: $selectedIndex) {
                        ForEach(0..<audioUnitComponents.auManagedInstruments.count, id: \.self) { index in
                            Label(audioUnitComponents.auManagedInstruments[index]!.name, systemImage: "pianokeys.inverse")
                        }
                    }
                    .navigationTitle("Menu")
                } detail: {
                    makeView5(index: selectedIndex ?? 0)
                        .id(selectedIndex)
                }
            }
            .onAppear(perform: startRunning)
        }
    }
    
    
    func makeView5(index: Int) -> some View {
        if index != 0 {
            let auManagedUnit = audioUnitComponents.auManagedInstruments[index]
            auManagedUnit!.loadAudioUnitViewController() { nsViewController in
                auManagedUnit!.setController(controller: nsViewController)
            }
            return AnyView(AUComponent3View(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents))
        }
        return AnyView(Text("No selection made"))
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

struct InstrumentsMenuSplitView_Preview: PreviewProvider {
    static var previews: some View {
        InstrumentsMenuSplitView(audioUnitComponents: AudioUnitComponents())
    }
}
