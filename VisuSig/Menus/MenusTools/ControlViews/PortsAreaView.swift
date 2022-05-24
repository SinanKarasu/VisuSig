//
//  PeopleView.swift
//  QGrid
//
//  Created by Karol Kulesza on 7/06/19.
//  Copyright © 2019 Q Mobile { http://Q-Mobile.IT }
//

import SwiftUI

//sik separate
fileprivate struct PortsSheetView: View {
    @Binding var isVisible: Bool
    @ObservedObject fileprivate var myLayout: PortsLayout
    
    var body: some View {
        
        VStack {
            GeometryReader { geometry in
                self.designerView(geometry)
            }
            Spacer()
            Button("OK") {
                self.isVisible = false
            }
        }
        .frame(width: 300, height: 300)
    }
    
    private func designerView(_ geometry: GeometryProxy) -> some View {
        return VStack {
            layoutSlider(name: "Columns:",
                         layoutParam: self.$myLayout.columns,
                         minValue: 1.0,
                         maxValue: CGFloat(PortsQConstants.columnsMax))
            layoutSlider(name: "vSpacing:",
                         layoutParam: self.$myLayout.vSpacing,
                         maxValue: self.myLayout.vSpacingMax(geometry))
            layoutSlider(name: "hSpacing:",
                         layoutParam: self.$myLayout.hSpacing,
                         maxValue: self.myLayout.hSpacingMax(geometry))
            layoutSlider(name: "vPadding:",
                         layoutParam: self.$myLayout.vPadding,
                         maxValue: self.myLayout.vPaddingMax(geometry))
            layoutSlider(name: "hPadding:",
                         layoutParam: self.$myLayout.hPadding,
                         maxValue: self.myLayout.hPaddingMax(geometry))
        }
        .padding([.bottom], 10)
    }
    
    private func layoutSlider(name: String,
                              layoutParam: Binding<CGFloat>,
                              minValue: CGFloat = 0.0,
                              maxValue: CGFloat) -> some View {
        HStack {
            Text(name)
            Text("\(Int(min(layoutParam.wrappedValue, maxValue)))")
            Slider(value: layoutParam, in: minValue...maxValue, step: 1.0)
        }
        .font(.headline).foregroundColor(.white)
        .padding([.horizontal], 10)
        .padding([.bottom], -10)
    }
}
///

fileprivate struct PortsQConstants {
    static let showDesigner = true
    static let columnsMax = 20
    static let vSpacingMaxToGeometryRatio: CGFloat = 0.5 // 50%
    static let vPaddingMaxToGeometryRatio: CGFloat = 0.3 // 30%
    static let hPaddingMaxToGeometryRatio: CGFloat = 0.3 // 30%
}

fileprivate class PortsLayout: ObservableObject {
    @Published var columns: CGFloat = 2.0
    @Published var vSpacing: CGFloat = 10.0
    @Published var hSpacing: CGFloat = 10.0
    @Published var vPadding: CGFloat = 0.0
    @Published var hPadding: CGFloat = 10.0
    
    func vSpacingMax(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height * PortsQConstants.vSpacingMaxToGeometryRatio
    }
    
    func hSpacingMax(_ geometry: GeometryProxy) -> CGFloat {
        return max(geometry.size.width/self.self.columns - 2 * self.hPadding, 1.0)
    }
    
    func vPaddingMax(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height * PortsQConstants.vPaddingMaxToGeometryRatio
    }
    
    func hPaddingMax(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width * PortsQConstants.hPaddingMaxToGeometryRatio
    }
}

struct PortsAreaView: View {
    
    let ports : [PortBase]
    
    @State private var portsSheetIsShowing = false
    
    @StateObject fileprivate var myLayout = PortsLayout()
    
    var body: some View {
        VStack {
            //Button("Resize") { self.portsSheetIsShowing.toggle() }
            GeometryReader { geometry in
                self.gridView(geometry)
                    .sheet(isPresented: $portsSheetIsShowing) {
                        PortsSheetView(isVisible: self.$portsSheetIsShowing, myLayout: myLayout)
                    }
            }
        }
        .frame(width: 100)
    }
    
    private func gridView(_ geometry: GeometryProxy) -> some View {
        QGrid(ports,
              columns: Int(self.myLayout.columns),
              columnsInLandscape: Int(self.myLayout.columns),
              vSpacing: min(self.myLayout.vSpacing, self.myLayout.vSpacingMax(geometry)),
              hSpacing: max(min(self.myLayout.hSpacing, self.myLayout.hSpacingMax(geometry)), 0.0),
              vPadding: min(self.myLayout.vPadding, self.myLayout.vPaddingMax(geometry)),
              hPadding: max(min(self.myLayout.hPadding, self.myLayout.hPaddingMax(geometry)), 0.0),
              showScrollIndicators: true)
        {
            GridPortView(port: $0)
        }
    }
}

fileprivate struct GridPortView: View {
    var port: PortBase
    
    var body: some View {
        
        ZStack {
            Circle()
                .fill(.red/*selectColor(port: port)*/)
                .background(GeometryReader { gp -> Color in
                    //let rect = gp.frame(in: .named(meshCoordinateSpace)) // < in specific container
                    //let rect = gp.frame(in: .local) // < in specific container

                    //DispatchQueue.main.async {
                        //print("Was center:\(port.center)")
                        //port.position = rect.origin
                        //print("Rect \(rect)")
                        //print(" : Origin: \(rect.origin)")
                    //}
                    return Color.yellow
                }
                    .overlay(Circle()
                        .stroke(
                            Color.black,
                            lineWidth:  5
                        )
                    )
                )
                .overlay(Text("?")
                    .multilineTextAlignment(.center)
                    .padding(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                )
                .frame(width: 20, height: 20, alignment: .center)
            Image(systemName: "arrowtriangle.down")
        }
        
    }
}

//#if DEBUG
//struct ListView_Previews : PreviewProvider {
//    static var previews: some View {
//        PeopleView()
//    }
//}
//#endif
