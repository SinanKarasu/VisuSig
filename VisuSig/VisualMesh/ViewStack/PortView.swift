//
//  PortView.swift
//  SiKNodeGraphEditor3
//
//  Created by Sinan Karasu on 1/18/22.
//

import SwiftUI

struct PortView: View {
    var port: PortBase
    @ObservedObject var selection: SelectionHandler
    
    @State var overImg = false
    var portInfo: some View {
        VStack {
            port.portInfo
            //Image(systemName: "arrowtriangle.down")

        }.padding([.top, .leading], 10)
    }
    
    var body: some View {
        ZStack {
            Text(port.name)
            Circle()
                .fill(.cyan) //selectColor(port: port)
                .overlay(
                    Circle()
                        .stroke(
                            selection.isPortSelected(port) ? Color.red : (overImg ? Color.yellow : Color.black),
                            lineWidth: (selection.isPortSelected(port)) ? 5 : 3
                        )
                )
                .overlay(portInfo
                    .multilineTextAlignment(.center)
                         //.padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                )
        }
        .frame(width: port.size.width, height: port.size.height)
        .onTapGesture {
            self.selection.selectPort(port)
        }
        .onHover{ over in
            if self.overImg != over {
                DispatchQueue.main.async {
                    overImg = over
                }
            }
        }
        .id(port)
    }
    
    
    
}




//struct PortView_Previews: PreviewProvider {
//    static var previews: some View {
//        PortView()
//    }
//}
