//
//  SimplePathView.swift
//  VisuSig
//
//  Created by Sinan Karasu on 2/16/22.
//

import SwiftUI

struct SimplePathView: View {
    let start: CGPoint
    let end: CGPoint

    var body: some View {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(.purple, lineWidth: 3)
    }
}

struct SimplePathView_Previews: PreviewProvider {
    static var previews: some View {
        SimplePathView(start: .zero, end: .zero)
    }
}
