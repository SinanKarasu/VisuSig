//
//  PortalPositionView.swift
//  PortalPositionView
//
//  Created by Sinan Karasu on 9/13/21.
//

import SwiftUI

struct PortalPositionView: View {
//    @Binding var portalPosition: CGPoint
//    @Binding var dragOffset: CGSize
//    @Binding var zoomScale: CGFloat
    var portalState: PortalState

    @Binding var whereAt: CGPoint
    @Binding var frame: CGRect
    // let proxySize: CGSize


    var body: some View {
        VStack {
            // let p = whereAt - proxySize/2
            HStack {
                Text(String(format: "drag offset = w:%04.0f\th:%04.0f",
                            arguments: [portalState.dragOffset.width, portalState.dragOffset.height])
                )
                .font(Font.system(.body, design: .monospaced))
                .foregroundColor(.orange)

                Text(String(format: "portal position = x:%04.0f\ty:%04.0f",
                            arguments: [portalState.portalPosition.x, portalState.portalPosition.y])
                )
                .font(Font.system(.body, design: .monospaced))
                .foregroundColor(.green)
            }
            HStack {
                Text(String(format: "where At x:%04.0f\ty:%04.0f",
                            arguments: [whereAt.x, whereAt.y])
                )
                .font(Font.system(.body, design: .monospaced))
                .foregroundColor(.red)

                Text(String(format: "zoom: %02.2f", portalState.zoomScale))
                    .font(Font.system(.body, design: .monospaced))
                    .foregroundColor(.purple)

                Text(String(format: "frame = x: %04.0f\ty: %04.0f\tw: %04.0f\th: %04.0f",
                            arguments: [frame.minX, frame.minY, frame.width, frame.height]))
                .font(Font.system(.body, design: .monospaced))
                .foregroundColor(.blue)
            }
        }
        .frame(height: 100)
    }
}
