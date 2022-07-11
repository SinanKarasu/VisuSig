//
//  EdgeProxy.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/11/22.
//

import Foundation

struct EdgeProxy: Identifiable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id = UUID()
    var edge: EdgeBase
    init(edge: EdgeBase) {
        self.edge = edge
        //self.end = edge.end
    }
}
