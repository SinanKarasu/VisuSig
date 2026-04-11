//
//  View+Extensions.swift
//  SiKNodeGraphEditor3
//
//  Created by Sinan Karasu on 1/15/22.
//

import SwiftUI

extension View {
//    func locationSiK(location: CGPoint, inSize: CGSize) -> some View {
//        return offset(x: location.x + inSize.width/2, y: location.y + inSize.height/2)
//    }
    func endTextEditing() {
        // NSApplication.shared.sendAction(#selector(NSResponder.resignFirstResponder), to: nil, from: nil)
        NSApp.keyWindow?.makeFirstResponder(nil)
    }
}

struct CustomBorder: ViewModifier {
    @State var color: Color
    @State var radius: CGFloat
    @State var lineWidth: CGFloat

    func body (content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

extension View {
    func addBorder(_ color: Color, radius: Int = 10, lineWidth: Int = 5) -> some View {
        self.modifier( CustomBorder(color: color, radius: CGFloat(radius), lineWidth: CGFloat(lineWidth) ) )
    }
}
