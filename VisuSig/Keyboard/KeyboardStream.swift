//
//  KeyboardStream.swift
//  AntlrExperiment
//
//  Created by Sinan Karasu on 12/4/20.
//

//Is this really needed? Seems to compile without it
import Combine

class KeyboardStream: KeyboardOutput, ObservableObject {
    func append(_ string: String) {
        characters.append(contentsOf: Array(string))
    }
    

    private(set) var characters: [Character] = [] {
        willSet {
            objectWillChange.send()
        }
    }
    var string: String {
        String(characters)
    }

    func append(_ character: Character) {
        characters.append(character)
    }

    func delete() {
        guard !characters.isEmpty else { return }
        characters.removeLast()
    }

    func clear() {
        guard !characters.isEmpty else { return }
        characters = []
    }

}
