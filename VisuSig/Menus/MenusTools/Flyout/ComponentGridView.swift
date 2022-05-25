//
//  ComponentGridView.swift
//  ComponentGridView
//
//  Created by Sinan Karasu on 8/29/21.
//

import SwiftUI

struct ComponentGridView: View {
    @Binding var selectedIndex: Int
    @Environment(\.presentationMode) var presentationMode
    
    let audioComponents: [Component]
    let cellSize: CGSize
    let viewSize: CGSize
    
    let padding: CGFloat = 10
    var columns: Int {
        var columns =  viewSize.width / cellSize.width
        while (columns * cellSize.width + 2*padding * columns) > viewSize.width {
            columns -= 1
        }
        return Int(max(1,columns))
    }
    
    var finalArray: [[Component]] {
        var array: [[Component]] = []
        var rowArray: [Component] = []
        for i in 0..<audioComponents.count {
            if i % columns == 0 {
                if i != 0 {
                    array.append(rowArray)
                }
                rowArray  = []
            }
            rowArray.append(audioComponents[i])
        }
        //        while rowArray.count < columns {
        //            rowArray.append(Component.empty)
        //        }
        array.append(rowArray)
        return array
    }
    
    var body: some View {
        ForEach(0..<finalArray.count, id: \.self) { rowIndex in
            HStack(spacing: 0) {
                ForEach(0..<finalArray[rowIndex].count, id: \.self) { columnIndex in
                    finalArray[rowIndex][columnIndex].componentIcon
                        .border(Color.yellow) // commentout
                        .frame(width: cellSize.width, height: cellSize.height)
                        .contentShape(Rectangle())
                        .padding(padding) // this adds padding around each shape.
                        .onTapGesture {
                            self.selectedIndex = rowIndex * self.columns + columnIndex
                            self.presentationMode.wrappedValue.dismiss()
                        }
                }
            }
            .frame(width: self.viewSize.width)
            .border(Color.red) // commentout
        }
    }
}

struct ComponentGridView_Previews: PreviewProvider {
    @State static var selectedIndex: Int = 1
    @StateObject static var audioUnitComponents = AudioUnitComponents()

    static var previews: some View {

        let cellSize = CGSize(width: 100, height: 100)
        let viewSize = CGSize(width:600, height:200)
        ComponentGridView(selectedIndex: $selectedIndex,
                    audioComponents: audioUnitComponents.audioUnitComponents,
                    cellSize: cellSize,
                    viewSize: viewSize
        )
    }
}
