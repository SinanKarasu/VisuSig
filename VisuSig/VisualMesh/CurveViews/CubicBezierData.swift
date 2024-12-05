//
//  CurveData.swift
//  SiKPathEditor2
//
//  Created by Sinan Karasu on 1/17/22.
//

import SwiftUI

@Observable
class CubicBezierData: Hashable {
    static func == (lhs: CubicBezierData, rhs: CubicBezierData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    var from: PortBase
    var to: PortBase
    var cp1: CGPoint = .zero
    var cp2: CGPoint = .zero
    var color = Color.red
    var edge: EdgeBase


//    init(from: PortBase, to: PortBase, cp1: CGPoint, cp2: CGPoint) {
//        self.from = from
//        self.to = to
//        self.cp1 = cp1
//        self.cp2 = cp2
//    }

//    convenience init(from: PortBase, to: PortBase) {
//        let bias = 4.0
//        let cp1 = CGPoint(x: (to.position.x-from.x)/bias+from.position.x, y: to.position.y)
//        let cp2 = CGPoint(x: to.position.x , y: (to.position.y-from.position.y)/bias+from.position.y)
//
//        self.init(from: from, to: to, cp1: cp1, cp2: cp2)
//
//    }

    init(edge: EdgeBase) {
        self.edge = edge
        self.from = edge.startPort
        self.to = edge.endPort
        reCalc()
       // self.init(from: from, to: to, cp1: cp1, cp2: cp2)
    }

    func reCalc() {
        let bias = 4.0
        self.cp1 = CGPoint(x: (self.to.x - self.from.x) / bias + self.from.x, y: to.y)
        self.cp2 = CGPoint(x: self.to.x, y: (to.y - self.from.y) / bias + self.from.y)
    }

    convenience init(edgeProxy: EdgeProxy) {
        self.init(edge: edgeProxy.edge)
    }
}
