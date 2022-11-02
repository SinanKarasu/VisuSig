//
//  FlyoutMenuMainView.swift
//  OpenMind2
//
//  Created by Sinan Karasu on 3/17/21.
//

import SwiftUI

struct FlyoutMenuOption {
    var image: Image
    var color: Color
    var action: () -> Void = {}
}
struct FlyoutMenuMainView: View {
    @State var isOpen = false
    let flyoutMenuOptions: [FlyoutMenuOption]
    let menuDiameter: CGFloat = 150
    let iconDiameter: CGFloat = 44

    var radius: CGFloat {
        return menuDiameter / 2
    }

    var body: some View {
        ZStack {
            Button( action: {
                withAnimation(.spring()) {
                    isOpen.toggle()
                }
                self.endTextEditing()
            }) {
                ZStack {
                    Circle()
                        .foregroundColor(.red)
                    Image(systemName: "plus")
                        .foregroundColor(.white) // Color of the plus sign
                        .font(.system(size: 18, weight: .medium))  // size of the plus sign
                        .rotationEffect(isOpen ? Angle.degrees(45) : .zero)
                }
                .buttonStyle(PlainButtonStyle())
                .clipShape(Circle())
                .frame(width: .zero, height: .zero)


                // .foregroundColor(.mint)
                // .background(.red)
            }
            ZStack {
                Circle()
                    .foregroundColor(.pink)
                    .opacity(0.1)
                ForEach(flyoutMenuOptions.indices, id: \.self) { index in
                    self.drawOption(index: index)
                }
            }
            .frame(width: .zero, height: .zero)
        }
    }

    func drawOption(index: Int) -> some View {
        let angle = (.pi / 4) * CGFloat(index) - .pi / 3
        let offset = CGSize(width: cos(angle) * radius,
                            height: sin(angle) * radius)
        let option = flyoutMenuOptions[index]
        return Button(action: {
            option.action()
        }) {
            ZStack {
                Circle()
                    .foregroundColor(option.color)

                option.image
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white) // sik change
            }
        }.buttonStyle(PlainButtonStyle())
            .frame(width: 44) // was width: 44
            .scaleEffect(isOpen ? 1.5 : 0.6)
            .offset(offset)
    }
}

// struct FlyoutMenuMainView_Previews: PreviewProvider {
//    @State static var isOpen = false
//    static var previews: some View {
//        FlyoutMenuMainView(isOpen: $isOpen)
//    }
// }
