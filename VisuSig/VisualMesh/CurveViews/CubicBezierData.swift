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
    var color = Color.cyan
    var edge: EdgeBase

    // MARK: - Dynamic control points

    /// Control points are computed on-the-fly from the current port positions,
    /// so wires update correctly when nodes are dragged.
    var cp1: CGPoint {
        let p1 = from.position
        let p2 = to.position
        let dy = abs(p2.y - p1.y)
        let bend = max(dy * 0.55, 60.0)
        // Exit downward from the output port, enter upward at the input port
        return CGPoint(x: p1.x, y: p1.y + bend)
    }

    var cp2: CGPoint {
        let p1 = from.position
        let p2 = to.position
        let dy = abs(p2.y - p1.y)
        let bend = max(dy * 0.55, 60.0)
        return CGPoint(x: p2.x, y: p2.y - bend)
    }

    // MARK: - Init

    init(edge: EdgeBase) {
        self.edge = edge
        self.from = edge.startPort
        self.to = edge.endPort
    }

    convenience init(edgeProxy: EdgeProxy) {
        self.init(edge: edgeProxy.edge)
    }
}
