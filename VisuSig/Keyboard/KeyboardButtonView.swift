//
//  KeyboardButtonView.swift
//  AntlrExperiment
//
//  Created by Sinan Karasu on 12/4/20.
//

import SwiftUI

struct KeyboardButtonView: View {
    let button: KeyboardButton
    
    let action: () -> Void
    
    init(_ button: KeyboardButton, _ action: @escaping () -> Void) {
        self.button = button
        self.action = action
    }
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                guard self.button != .placeholder else { return }
                self.action()
            }) {
                
                Group {
                    GeometryReader { geometry in
                    if self.button == .placeholder {
                        EmptyView()
                    }
                    else {
                        Text(self.button.label)
                            .font(self.button.font)
                            .foregroundColor(self.button.foregroundColor)
                        //.frame(height: geometry.size.width*self.button.heightMultiplier)
                    }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            //.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

//sik fix
//struct KeyboardButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        KeyboardButtonView(KeyboardButton.digit("X"))
//    }
//}
