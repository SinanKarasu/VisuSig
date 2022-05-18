//
//  KeyboardOutput.swift
//  AntlrExperiment
//
//  Created by Sinan Karasu on 12/4/20.
//

import Foundation

protocol KeyboardOutput {

    func append(_ character: Character)
    
    func append(_ string: String)


    func delete()

    func clear()
}
