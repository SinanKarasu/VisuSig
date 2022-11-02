//
//  PortalState.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/21/22.
//

import Foundation


class PortalState: ObservableObject {
    @Published var portalPosition: CGPoint = .zero
    @Published var dragOffset: CGSize = .zero
    @Published var isDragging = false
    @Published var isDraggingMesh = false
    @Published var isWiring = false

    // zooming
    @Published var zoomScale: CGFloat = 1.0
    @Published var initialZoomScale: CGFloat?
    @Published var initialPortalPosition: CGPoint?
    @Published var frame: CGRect = .zero
}
