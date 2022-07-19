
//
//  ComponentsGridView.swift
//  ComponentsGridView
//
//  Created by Sinan Karasu on 8/29/21.
//

import SwiftUI

struct ComponentsGridView: View {
    //@Binding var selectedIndex: Int
    @ObservedObject var audioUnitComponents: AudioUnitComponents
    let cellSize = CGSize(width: 150.0, height: 60.0)
    let viewSize = CGSize(width:800.0, height:200.0)
    var body: some View {
        let _ = print("\(cellSize) , \(viewSize)")
        GeometryReader { geometry in
            List {
                Text("Select A Shape")
                ComponentTableView(//selectedIndex: $selectedIndex,
                               audioComponents: audioUnitComponents.audioUnitComponents,
                           cellSize: cellSize,
                           //viewSize: geometry.size
                           viewSize: viewSize
                )
                .listRowBackground(Color.black)
            }
            .listRowInsets(EdgeInsets(top:0, leading:0, bottom: 0, trailing: 0))
        }
    }
}


struct ShapeGridView_Previews: PreviewProvider {
    @State static var selectedIndex: Int = 0
    @StateObject static var audioUnitComponents = AudioUnitComponents()
    static var previews: some View {
        ComponentsGridView( audioUnitComponents: audioUnitComponents)
    }
}
