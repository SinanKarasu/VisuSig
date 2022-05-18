//
//  GridCompleteView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 2/5/22.
//

import SwiftUI

struct GridCompleteView: View {
    let size: CGFloat
    var body: some View {
        GeometryReader { proxy in
            let rect = proxy.size
            let half = rect/CGFloat(2.0)
            // Draw the axes
            Path() { path in
                path.move(to: CGPoint(x: -half.width, y:0))
                path.addLine(to: CGPoint(x: half.width, y: 0))

                path.move(to: CGPoint(x: 0, y:-half.height))
                path.addLine(to: CGPoint(x: 0, y: half.height))
            }
            .offsetBy(dx: rect.width/2, dy: rect.height/2)
            .stroke(Color.red, lineWidth: 0.5).opacity(1.0)
            // draw the horizontal lines
            Path() { path in
                for row in stride(from: 0, through: rect.height/2, by: size) {

                    if row != 0 { // skip the x-axis
                        path.move(to: CGPoint(x: -half.width, y:row))
                        path.addLine(to: CGPoint(x: half.width, y: row))

                        path.move(to: CGPoint(x: -half.width, y:-row))
                        path.addLine(to: CGPoint(x: half.width, y: -row))
                    }
                }
                // draw the vertical lines
                for col in stride(from: 0, through: rect.width/2, by: size) {
                    if col != 0 { // skip the y-axis
                        path.move(to: CGPoint(x: col, y:-half.height))
                        path.addLine(to: CGPoint(x: col, y: half.height))

                        path.move(to: CGPoint(x: -col, y:-half.height))
                        path.addLine(to: CGPoint(x: -col, y: half.height))
                    }
                }
            }
            .offsetBy(dx: rect.width/2, dy: rect.height/2)
            .stroke (Color.yellow, lineWidth: 0.5).opacity(0.3)
        }
    }
}

struct GridCompleteView_Previews: PreviewProvider {
    static var previews: some View {
        GridCompleteView(size: 30)
    }
}
