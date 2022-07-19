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
    //let audioComponents: [Component]
    var cellSize: CGSize
    var viewSize: CGSize
    
    let padding: CGFloat = 10
    var columns: Int {
        var cols =  viewSize.width / cellSize.width
        while (cols * cellSize.width + 2*padding * cols) > viewSize.width {
            cols -= 1
        }
        return Int(max(1,cols))
    }
    
    
    
    var selectedCity: String {
//        if let selection = selection {
//            return selection.uuidString
//        } else {
//            return "no selection"
//        }
        
        // 1
        guard let selection = selection else {
            return "no selection"
        }
        
        // 2
        let event = audioUnitComponents.audioUnitComponents.first {
            $0.id == selection
        }
        // 3
        return event!.nameAndMFG
    }

    
    var body: some View {
        VStack {
            Text("SELECTION: ").foregroundColor(.red) + Text(selectedCity)
            Text("Entries:\($audioUnitComponents.audioUnitComponents.count)")
            Table(audioUnitComponents.audioUnitComponents, selection: $selection) {
                //Text("id") { Text(String($0.id))}
                TableColumn("Name") { Text($0.name)}
                TableColumn("Mfg", value: \.mfg)
                TableColumn("Custom View")  {  Text("\($0.hasCustomView ? "true":"false")") }
//                TableColumn("Seconds from GMT", value: \.offset) { Text("\($0.offset)")
                
            }
        }
        .frame(width: 600, height:800)
    }

//    var body: some View {
//        let _ = print(">>\(cellSize) , \(viewSize)")
//
//        List(audioComponents) { item in
//            item.componentIcon
//        }
//    }
}

//extension UUID: Comparable {
//    public static func <(lhs: UUID, rhs: UUID) -> Bool {
//        return lhs < rhs
//    }
//}

//struct ComponentTableView_Previews: PreviewProvider {
//    @State static var selectedIndex: Int = 1
//    @StateObject static var audioUnitComponents = AudioUnitComponents()
//
//    static var previews: some View {
//
//        let cellSize = CGSize(width: 200, height: 100)
//        let viewSize = CGSize(width:600, height:800)
//        ComponentTableView(//selectedIndex: $selectedIndex,
//                          audioComponents: audioUnitComponents.audioUnitComponents,
//                          cellSize: cellSize,
//                          viewSize: viewSize
//        )
//    }
//}
