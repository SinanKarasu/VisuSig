//
//  EntityViewImpl.swift
//  EntityViewImpl
//
//  Created by Sinan Karasu on 8/28/21.
//

import Foundation
import SwiftUI

struct MouseLocationView: NSViewRepresentable {
    let onMove: (NSPoint, CGRect) -> Void
    init(onMove: @escaping (NSPoint, CGRect) -> Void) {
        self.onMove = onMove
    }
    final class MouseLocationNSView: NSView {

        var oldMousePosition: NSPoint = .zero
        var oldFrameOrigin: NSPoint = .zero
        let onMove: (NSPoint, CGRect) -> Void


        init(onMove: @escaping (NSPoint, CGRect) -> Void) {
            self.onMove = onMove
            super.init(frame: NSRect(x: 0, y: 0, width: 100, height: 200))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)

            NSColor.clear.setFill()
            dirtyRect.fill()
        }
        // These do work.
//        override func mouseDown(with event: NSEvent) {
//            //self.oldFrameOrigin = self.superview!.frame.origin
//            self.oldMousePosition = self.convert(event.locationInWindow, from: nil)
//            print("mouseDown:\(oldMousePosition)")
//        }
//
//        override func mouseUp(with event: NSEvent) {
//            //self.oldFrameOrigin = self.superview!.frame.origin
//            self.oldMousePosition = self.convert(event.locationInWindow, from: nil)
//            print("mouseDown:\(oldMousePosition)")
//        }
//
//        override func mouseDragged(with event: NSEvent) {
//            self.oldMousePosition = self.convert(event.locationInWindow, from: nil)
//            let p = self.convert(oldMousePosition, to: nil)
//            print("mouseDragged: \(p)")
//        }

        override func mouseMoved(with event: NSEvent) {
            self.oldMousePosition = self.convert(event.locationInWindow, from: nil)
            onMove(oldMousePosition, self.bounds)


        }

        var trackingArea : NSTrackingArea?

        override func updateTrackingAreas() {
            if trackingArea != nil {
                self.removeTrackingArea(trackingArea!)
            }
            let options : NSTrackingArea.Options =
            [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]
            trackingArea = NSTrackingArea(rect: self.bounds, options: options,
                                          owner: self, userInfo: nil)
            self.addTrackingArea(trackingArea!)
        }


    }

    func makeNSView(context: NSViewRepresentableContext<MouseLocationView>) -> MouseLocationNSView {
        return MouseLocationNSView(onMove: onMove)
    }

    func updateNSView(_ nsView: MouseLocationNSView, context: NSViewRepresentableContext<MouseLocationView>) {
        // do nothing
    }
}
