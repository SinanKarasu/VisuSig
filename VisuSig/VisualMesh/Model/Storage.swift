//
//  Storage.swift
//  VisuSig
//
//  Created by Sinan Karasu on 1/21/22.
//

import Foundation
class Storage {

    static func restore() -> Mesh {
        let proxy = StorageHandler().restore()
        let mesh = Mesh(storage: proxy)
        return mesh
    }

    func save(mesh: Mesh) {
        do {
            try StorageHandler().save(mesh.storageObject)
            DLog("MSG: Mesh save OK")
        } catch {
            DLog("ERROR: Mesh save failed -",error)
        }
    }
    
    
}
