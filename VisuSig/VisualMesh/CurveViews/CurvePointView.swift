//
//  CurvePointView.swift
//  SiKPathEditor2
//
//  Created by Sinan Karasu on 1/17/22.
//

import SwiftUI

struct CurvePointView: View {
    private let size: CGFloat = 20
    @Binding var point: CGPoint
    var color: Color = .white


    @GestureState private var gestureState: CGPoint = .zero
    // @State private var draggingLocation = CGPoint.zero
    // @State private var startLocation = CGPoint.zero
    @State private var dragging = false
    @State var point0: CGPoint = .zero


    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 10, coordinateSpace: .named(meshCoordinateSpace))
            .updating($gestureState) { value, state, _ in
                state = value.location
            }
            .onEnded { value in
                self.dragging = false
                point = point0 + (value.location - value.startLocation)
                DispatchQueue.main.async {
                    point0 = point
                }
            }
            .onChanged { value in
                if !self.dragging {
                    DispatchQueue.main.async {
                        self.dragging = true
                        point0 = point
                        point = point0 + (value.location - value.startLocation)
                    }
                } else {
                    DispatchQueue.main.async {
                        point = point0 + (value.location - value.startLocation)
                    }
                }
            }
        GeometryReader { _ in
            Circle()
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 2)
                )
                .offset(x: -size / 2, y: -size / 2)
                .offset(x: point.x, y: point.y)
        }
        .gesture(dragGesture)
    }
}

struct CurvePointView_Previews: PreviewProvider {
    @State static var point: CGPoint = .zero
    static var previews: some View {
        CurvePointView(point: $point)
    }
}
