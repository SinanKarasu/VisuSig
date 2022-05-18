//
//  KeyboardGrid.swift
//  AntlrExperiment
//
//  Created by Sinan Karasu on 12/4/20.
//

import SwiftUI

struct KeyboardGrid<Content: View>: View {
    private let content: () -> Content
    
    init<Data, RowID, ColID, CellContent> (
        data: Data,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder cellContent: @escaping (_ element: Data.Element.Element) -> CellContent
    )
    where Content == VStack<ForEach<Data, RowID, HStack<ForEach<Data.Element, ColID, CellContent>>>>,
    Data : RandomAccessCollection,
    Data.Element : RandomAccessCollection,
    RowID == Data.Element,
    ColID == Data.Element.Element,
    CellContent : View
    {
        content = {
            VStack(alignment: alignment) {
                ForEach(data, id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { cell in
                            cellContent(cell)
                        }
                    }
                }
            }
        }
    }
    
    
    var body: some View {
        content()
    }
}

struct Grid_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardGrid(data: [[1, 2, 3], [4, 5, 6], [7], [8, 9]]) { element in
            Text(String(element))
        }
    }
}

