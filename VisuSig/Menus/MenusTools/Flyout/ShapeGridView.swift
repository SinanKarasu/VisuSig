
//
//  ShapeGridView.swift
//  ShapeGridView
//
//  Created by Sinan Karasu on 8/29/21.
//

import SwiftUI

struct ShapeGridView: View {
    @Binding var selectedIndex: Int
    @ObservedObject var audioUnitComponents: AudioUnitComponents

    var body: some View {
        let cellSize = CGSize(width: 100, height: 100)
        let viewSize = CGSize(width:600, height:200)
        GeometryReader { geometry in
            List {
                Text("Select A Shape")
                ShapesGridView(selectedIndex: $selectedIndex,
                               allShapes: audioUnitComponents.audioUnitComponents,
                           cellSize: cellSize,
                           //viewSize: geometry.size
                           viewSize: viewSize
                )
                .listRowBackground(Color.green)
            }
            .listRowInsets(EdgeInsets(top:0, leading:0, bottom: 0, trailing: 0))
        }
    }
}


struct ShapeGridView_Previews: PreviewProvider {
    @State static var selectedIndex: Int = 0
    @StateObject static var audioUnitComponents = AudioUnitComponents()
    static var previews: some View {
        ShapeGridView(selectedIndex: $selectedIndex, audioUnitComponents: audioUnitComponents)
    }
}
