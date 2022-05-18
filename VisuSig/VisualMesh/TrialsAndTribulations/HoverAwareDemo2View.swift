//
//  HoverAwareDemo2View.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/21/22.
//

import SwiftUI

struct HoverAwareDemo2View: View {
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Color.black.opacity(opacity).onHoverAware { (hovering: Bool) in
            withAnimation(Animation.spring()) {
                self.opacity = hovering ? 0.5 : 1.0
            }
        }
    }
}

struct HoverAwareDemo2View_Previews: PreviewProvider {
    static var previews: some View {
        HoverAwareDemo2View()
    }
}
