//
//  KeyboardView.swift
//  AntlrExperiment
//
//  Created by Sinan Karasu on 12/4/20.
//

import SwiftUI

struct KeyboardView: View {
    private let actionButtons: [[KeyboardButton]] = [
        [.action(.delete), .action(.clear)]]

    private let inputButtons: [[KeyboardButton]] = [
        [ .digit("9"), .digit("8"), .digit("7"), .arithmetic("÷") ],
        [ .digit("6"), .digit("5"), .digit("4"), .arithmetic("×") ],
        [ .digit("3"), .label("AbCdE"), .digit("1"), .arithmetic("-") ],
        [ .placeholder, .digit("0"), .placeholder, .arithmetic("+") ]
    ]


    private var output: KeyboardOutput

    init(output: KeyboardOutput) {
        self.output = output
    }

    var body: some View {
        GeometryReader{ reader in
            VStack {
                makeGrid(buttons: actionButtons)
                makeGrid(buttons: inputButtons)
            }
            .frame(width:300, height:600)//.frame(height: 144.0)//.frame(width:600, height:300)
        }
    }

    private func makeGrid(buttons: [[KeyboardButton]]) -> some View {
        KeyboardGrid(data: buttons) { button in
            KeyboardButtonView(button) {
                button.execute(self.output)
            }
            // minWidth is the background size for the buttons
            .frame(minWidth:30, minHeight:30)
            .background(button.backgroundColor)
        }
    }


    
}

struct KeyboardView_Previews: PreviewProvider {
    private struct DummyOutput : KeyboardOutput {
        func append(_ string: String) {
            
        }
        

        func append(_ character: Character) { }

        func delete() { }

        func clear() { }
    }
    static var previews: some View {
        KeyboardView(output: DummyOutput())
    }
}
