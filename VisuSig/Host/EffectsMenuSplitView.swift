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
    @State private var selectedUnit: Int?
    
    
    var audioUnitManager: AudioUnitManager {
        audioUnitComponents.audioUnitManager
    }
    
    let audioUnitTypes: [AudioUnitType] = [ .effect, .instrument]
    var body: some View {
        return GeometryReader { reader in
            VStack {
                VStack {
                    Text("EffectsMenuView")
                    Text("Effects Count: \(audioUnitComponents.audioUnitComponents.count)")
                    Text("Managed Count: \(audioUnitComponents.auManagedEffectUnits.count)")
                    
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.blue, lineWidth: 5)
                    HStack {
                        Divider()
                        VStack {
                            Divider()
                            NavigationSplitView (columnVisibility: $columnVisibility) {
                                List(selection: $selectedUnit) {
                                    ForEach(0..<audioUnitComponents.auManagedEffectUnits.count, id: \.self) { index in
                                        if let x = audioUnitComponents.auManagedEffectUnits[index] {
                                            Label(x.name, systemImage: "waveform.circle")
                                        } else {
                                            Label("No Effect", systemImage: "waveform.circle")
                                        }
                                    }
                                }
                                //.listRowInsets(EdgeInsets(top: 0, leading: 200, bottom: 0, trailing: 0))
                                //.listStyle(PlainListStyle())
                                .navigationTitle("Menu")
                                
                            } detail: {
                                if let selectedUnit = selectedUnit {
                                    makeView5(index: selectedUnit)
                                        .id(selectedUnit)
                                } else {
                                    Text("Choose something")
                                }
                            }
                        }
                    }
                }
            }
            //.border(.blue) //BUG. Enable this line
            .onAppear(perform: startRunning)
        }
        
    }
    
    
    func makeView5(index: Int) -> some View {
        //if index != 0 {
        if let auManagedUnit = audioUnitComponents.auManagedEffectUnits[index] {
            auManagedUnit.loadAudioUnitViewController() { nsViewController in
                auManagedUnit.setController(controller: nsViewController)
            }
            return AnyView(AUComponent3View(auManagedUnit: auManagedUnit, audioUnitComponents: audioUnitComponents))
        } else {
            return AnyView(Text("Select an effect unit"))
        }
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
