//
//  WireEditView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/17/22.
//

import SwiftUI

struct WireEditView: View {
    var edgeProxy: EdgeProxy
    var selection: SelectionHandler

    var body: some View {
        GeometryReader { _ in
            LayeredWire(cubicBezierData: edgeProxy.edge.data!, selection: selection)
                .onTapGesture {
                    print("Got a Tap gesture in Wire View")
                }
                .id(edgeProxy)
        }
    }
}
