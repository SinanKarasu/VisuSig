//
//  ContextMenuProtocol.swift
//  ContextMenuProtocol
//
//  Created by Sinan Karasu on 9/17/21.
//

import Foundation

protocol ContextMenuProtocol {

}

extension ContextMenuProtocol {

    func selectHearts(mesh: Mesh, whereAt: CGPoint, containerSize: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) {

        //let newpoint = whereAt

        let p = (whereAt - containerSize/2.0 - portalPosition) / zoomScale
        let node = NodeBase(position: p, text: "child x:\(p.x) y:\(p.y)")
        mesh.addNode(node)
    }
    func selectClubs() { print("Clubs") }
    func selectSpades() { print("Spades") }
    
    func selectDiamonds() { print("Diamonds") }

}
