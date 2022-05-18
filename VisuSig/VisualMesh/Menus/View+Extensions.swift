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
        //NSApplication.shared.sendAction(#selector(NSResponder.resignFirstResponder), to: nil, from: nil)
        NSApp.keyWindow?.makeFirstResponder(nil)

    }

}
