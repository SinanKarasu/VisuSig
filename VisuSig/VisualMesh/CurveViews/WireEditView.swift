//
//  WireEditView.swift
//  SiKPathEditor2
//
//  Created by Sinan Karasu on 1/17/22.
//

import SwiftUI

struct WireEditView: View {
	var edgeProxy: EdgeProxy
	
	var selection: SelectionHandler
	var showPoints = false
	
	
	var body: some View {
		GeometryReader { _ in
			LayeredWire(cubicBezierData: edgeProxy.edge.data!, selection: selection)
				.onTapGesture { // This one causes delay
					print("Got a Tap gesture in Wire View")
				}
				.id(edgeProxy)
		}
	}
}

// struct WireEditView_Previews: PreviewProvider {
//    static var previews: some View {
//        WireEditView(edgeProxy: EdgeProxy(edge: EdgeBase(data: nil)), selection: SelectionHandler())
//    }
// }
