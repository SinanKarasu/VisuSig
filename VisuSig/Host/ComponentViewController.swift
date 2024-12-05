//
//  ComponentViewController.swift
//  SiKAUv3HostNew
//
//  Created by Sinan Karasu on 1/24/22.
//

import Foundation
import CoreAudioKit

import Cocoa


class ComponentViewController: AUViewController, Identifiable {
    class CustomView: NSView {
        var viewSize: CGSize


        init( viewSize: CGSize = CGSize(width: 800, height: 600)) {
            self.viewSize = viewSize
            super.init(frame: NSRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            return viewSize
        }
    }

    let id = UUID()

    var viewSize = CGSize(width: 800, height: 600) //sik this is the size of component
    var subView: NSView?

    init(subView: NSView? = nil) {
        self.subView = subView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = CustomView(viewSize: viewSize)
    }

    func presentUserInterface(_ subview: NSView?) {
        if let subview = subview {
            view.addSubview(subview)
            subview.pinToSuperview()
        }
    }
}
