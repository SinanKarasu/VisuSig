//
//  KeyboardButton.swift
//  AntlrExperiment
//
//  Created by Sinan Karasu on 12/4/20.
//

import Foundation
import SwiftUI

enum KeyboardButton : Hashable {
    
    enum Action : Hashable {
        case delete
        case clear
        
        var label: String {
            switch self {
            case .delete:
                return "Delete"
            case .clear:
                return "Clear"
            }
        }
        
        func execute(_ output: KeyboardOutput) {
            switch self {
            case .delete:
                output.delete()
            case .clear:
                output.clear()
            }
        }
    }
    
    case digit(_ character: Character)
    case label(_ string: String)
    case arithmetic(_ character: Character)
    case action(_ action: Action)
    case placeholder
}


extension KeyboardButton {
    
    func execute(_ output: KeyboardOutput) {
        switch self {
        case .digit(let character):
            output.append(character)
        case .arithmetic(let character):
            output.append(character)
        case .action(let action):
            action.execute(output)
        case .placeholder:
            preconditionFailure("Placeholder can not be executed")
        case .label(let string):
            output.append(string)
        }
    }
}

extension KeyboardButton {
    var label: String {
        switch self {
        case .digit(let character):
            return String(character)
        case .arithmetic(let character):
            return String(character)
        case .action(let action):
            return action.label
        case .placeholder:
            preconditionFailure("Placeholder has no label")
        case .label(let string):
            return string
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .digit:
            return Color(white: 0.1)
        case .arithmetic:
            return Color(white: 0.1)
        case .action:
            return Color(white: 0.9)
        case .placeholder:
            return Color.clear
        case .label:
            return Color(white: 0.7)
            
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .digit:
            return Color.yellow
        case .arithmetic:
            return Color.orange
        case .action:
            return Color.blue
        case .placeholder:
            return Color.clear
        case .label:
            return Color.purple
        }
    }
    
    var font: Font {
        switch self {
        case .digit:
            return Font.title
        case .arithmetic:
            return Font.title
        case .action:
            return Font.headline
        case .placeholder:
            preconditionFailure("Placeholder has no font")
        case .label:
            return Font.headline
        }
    }
    
    var heightMultiplier: CGFloat {
        switch self {
        case .action:
            return 0.25
        default:
            return 1.0
        }
    }
}

extension KeyboardButton: Identifiable {
    var id: Self { self }
}

