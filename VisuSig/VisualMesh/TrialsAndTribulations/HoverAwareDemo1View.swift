//
//  HoverAwareDemo1View.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/21/22.
//

import SwiftUI

struct HoverAwareDemo1View: View {
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            HoverAwareView { (hovering: Bool) in
                withAnimation(Animation.spring()) {
                    self.opacity = hovering ? 0.8 : 0.4
                }
            }

            Color.green.opacity(opacity)
        }
    }
}

struct HoverAwareDemo1View_Previews: PreviewProvider {
    static var previews: some View {
        HoverAwareDemo1View()
    }
}
