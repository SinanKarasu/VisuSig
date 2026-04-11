//
//  PortalState.swift
//  VisuSig
//
//  Created by Sinan Karasu on 7/21/22.
//

import Foundation

@Observable
class PortalState {
	var portalPosition: CGPoint = .zero
	var dragOffset: CGSize = .zero
	var isDragging = false
	var isDraggingMesh = false
	var isWiring = false
	
	// zooming
	var zoomScale: CGFloat = 1.0
	var initialZoomScale: CGFloat?
	var initialPortalPosition: CGPoint?
	var frame: CGRect = .zero
}
