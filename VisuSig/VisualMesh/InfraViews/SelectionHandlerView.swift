//
//  SelectionHandlerView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 2/16/22.
//

import SwiftUI

struct SelectionHandlerView: View {
    @ObservedObject var selection: SelectionHandler
    var body: some View {
        HStack {
            Text("Selection:")
            Text(String(format: "dragging start, end = s:%04.0f,%04.0f\te:%04.0f, %04.0f",
                        arguments: [selection.startLocation.x, selection.startLocation.y, selection.draggingLocation.x, selection.draggingLocation.y])
            )
            .font(Font.system(.body, design: .monospaced))
            .foregroundColor(.orange)
        }
    }
}

struct SelectionHandlerView_Previews: PreviewProvider {
    static var previews: some View {
        SelectionHandlerView(selection: SelectionHandler())
    }
}
