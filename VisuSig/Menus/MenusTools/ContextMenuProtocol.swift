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

    func addNewNode(mesh: Mesh, whereAt: CGPoint, containerSize: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) {
        let p = mesh.meshCoordinates(whereAt: whereAt, containerSize: containerSize, portalPosition: portalPosition, zoomScale: zoomScale)
        let node = NodeBase(text: "child x:\(p.x) y:\(p.y)", position: p, payload: nil)
        mesh.addNode(node)
    }
    
    func selectClubs() { print("Clubs") }
    func selectSpades() { print("Spades") }
    
    func selectDiamonds() { print("Diamonds") }

}
