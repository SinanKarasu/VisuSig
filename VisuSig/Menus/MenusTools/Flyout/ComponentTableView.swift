//
//  ComponentGridView.swift
//  ComponentGridView
//
//  Created by Sinan Karasu on 8/29/21.
//

import SwiftUI

struct ComponentTableView: View {
    //@Environment(\.presentationMode) var presentationMode
    //@Binding var selectedIndex: Int
    
    @State private var selection: UUID? = nil
    
    @State private var order: [KeyPathComparator<Component>] = [
        .init(\.nameAndMFG, order: SortOrder.forward)
    ]

    @ObservedObject var audioUnitComponents: AudioUnitComponents
    @ObservedObject var selectionHandler: SelectionHandler
    //let audioComponents: [Component]
//    var cellSize: CGSize
//    var viewSize: CGSize
    
    let padding: CGFloat = 10
//    var columns: Int {
//        var cols =  viewSize.width / cellSize.width
//        while (cols * cellSize.width + 2*padding * cols) > viewSize.width {
//            cols -= 1
//        }
//        return Int(max(1,cols))
//    }
    
    
    
    var selectedUnit: String {
        guard let selection = selection else {
            return "no selection"
        }
        
        let event = audioUnitComponents.audioUnitComponents.first {
            $0.id == selection
        }
        return event!.nameAndMFG
    }

    
    var body: some View {
        VStack {
            Text("SELECTION: ").foregroundColor(.red) + Text(selectedUnit)
            Text("Entries:\($audioUnitComponents.audioUnitComponents.count)")
            Table(audioUnitComponents.audioUnitComponents, selection: $selection) {
                TableColumn("Name") { Text($0.name)} //.width(min: 35, ideal: 35, max:   60)
                TableColumn("Mfg", value: \.mfg) //.width(min: 35, ideal: 35, max:   60)
                TableColumn("Type")             { viewOfStr($0.avAudioUnitComponent?.typeName) } //.width(min: 35, ideal: 35, max:   60)
                TableColumn("Custom\nView")     { viewOfBool($0.avAudioUnitComponent?.hasCustomView)  }.width(min: 35, ideal: 35, max:   60)
                TableColumn("MIDI\nInput")      { viewOfBool($0.avAudioUnitComponent?.hasMIDIInput) }.width(min: 35, ideal: 35, max:   60)
                TableColumn("MIDI\nOutput")     { viewOfBool($0.avAudioUnitComponent?.hasMIDIOutput) }.width(min: 35, ideal: 35, max:   60)
                TableColumn("PASS\nAUVal")      { viewOfBool($0.avAudioUnitComponent?.passesAUVal) }.width(min: 35, ideal: 35, max:   60)
            }
        }
        .frame(width: 800, height:800)
    }

    func viewOfBool(_ val: Bool?) -> some View {
        if let val = val {
            return Text(val ? "Y":"N")
        } else {
            return Text("unknown")
        }
    }
    
    func viewOfStr(_ val: String?) -> some View {
        if let val = val {
            return Text(val)
        } else {
            return Text("unknown")
        }
    }
}


struct ComponentTableView_Previews: PreviewProvider {
    @State static var selectedIndex: Int = 1
    @StateObject static var audioUnitComponents = AudioUnitComponents()

    static var previews: some View {
        ComponentTableView(audioUnitComponents: audioUnitComponents, selectionHandler: SelectionHandler())
    }
}
