//
//  PeopleView.swift
//  QGrid
//
//  Created by Karol Kulesza on 7/06/19.
//  Copyright © 2019 Q Mobile { http://Q-Mobile.IT }
//

import SwiftUI

//sik separate
fileprivate struct SheetView: View {
    @Binding var isVisible: Bool
    @ObservedObject fileprivate var myLayout: MyLayout
    
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
                         maxValue: CGFloat(QConstants.columnsMax))
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

fileprivate struct QConstants {
    static let showDesigner = true
    static let columnsMax = 2
    static let vSpacingMaxToGeometryRatio: CGFloat = 0.5 // 50%
    static let vPaddingMaxToGeometryRatio: CGFloat = 0.3 // 30%
    static let hPaddingMaxToGeometryRatio: CGFloat = 0.3 // 30%
}

fileprivate class MyLayout: ObservableObject {
    @Published var columns: CGFloat = 1.0
    @Published var vSpacing: CGFloat = 10.0
    @Published var hSpacing: CGFloat = 10.0
    @Published var vPadding: CGFloat = 0.0
    @Published var hPadding: CGFloat = 10.0
    
    func vSpacingMax(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height * QConstants.vSpacingMaxToGeometryRatio
    }
    
    func hSpacingMax(_ geometry: GeometryProxy) -> CGFloat {
        return max(geometry.size.width/self.self.columns - 2 * self.hPadding, 1.0)
    }
    
    func vPaddingMax(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height * QConstants.vPaddingMaxToGeometryRatio
    }
    
    func hPaddingMax(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width * QConstants.hPaddingMaxToGeometryRatio
    }
}

struct EffectsToolsView: View {
    
    @State private var sheetIsShowing = false
    
    @StateObject fileprivate var myLayout = MyLayout()
    
    var body: some View {
        VStack {
            Button("Resize") { self.sheetIsShowing.toggle() }
            GeometryReader { geometry in
                self.gridView(geometry)
                    .sheet(isPresented: $sheetIsShowing) {
                        SheetView(isVisible: self.$sheetIsShowing, myLayout: myLayout)
                    }
            }
        }
        .frame(width: 100)
    }
    
    private func gridView(_ geometry: GeometryProxy) -> some View {
        QGrid(EffectStorage.people,
              columns: Int(self.myLayout.columns),
              columnsInLandscape: Int(self.myLayout.columns),
              vSpacing: min(self.myLayout.vSpacing, self.myLayout.vSpacingMax(geometry)),
              hSpacing: max(min(self.myLayout.hSpacing, self.myLayout.hSpacingMax(geometry)), 0.0),
              vPadding: min(self.myLayout.vPadding, self.myLayout.vPaddingMax(geometry)),
              hPadding: max(min(self.myLayout.hPadding, self.myLayout.hPaddingMax(geometry)), 0.0),
              showScrollIndicators: true)
        {
            GridCell(person: $0)
        }
    }
}

fileprivate struct GridCell: View {
    var person: Effect
    
    var body: some View {
        ZStack() {
            //Image(person.imageName)
            Image(systemName: "waveform")
            //.foregroundColor(.green)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
            //.shadow(color: .purple, radius: 5)
            //.padding([.horizontal, .top], 7)
                .foregroundColor(.green)
                .opacity(0.4)
            
            VStack {
                Text(person.firstName).lineLimit(1)
                Text(person.lastName).lineLimit(1)
            }
        }
        //.font(.headline).foregroundColor(.white)
    }
}

//#if DEBUG
//struct ListView_Previews : PreviewProvider {
//    static var previews: some View {
//        PeopleView()
//    }
//}
//#endif
