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
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.green, lineWidth: 5)
                    HStack {
                        Divider()
                        
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
                }
            }

            //.onAppear(perform: startRunning)
        }
    }
    
    
    func makeView5(index: Int) -> some View {
        if index != 0 {
            let auManagedUnit = audioUnitComponents.auManagedInstruments[index]
            auManagedUnit!.loadAudioUnitViewController() { nsViewController in
                auManagedUnit!.setController(controller: nsViewController)
            }
            return AnyView(AUComponentView(auManagedUnit: auManagedUnit!, audioUnitComponents: audioUnitComponents))
        }
        if audioUnitComponents.auManagedInstruments.count < 1 {
            return AnyView(Text("Instruments are DISABLED"))
        }
        return AnyView(Text("No selection made"))
    }
    
//    func startRunning() {
//        audioUnitComponents.startRunning()
//    }
}

struct InstrumentsMenuSplitView_Preview: PreviewProvider {
    static var previews: some View {
        InstrumentsMenuSplitView(audioUnitComponents: AudioUnitComponents())
    }
}
