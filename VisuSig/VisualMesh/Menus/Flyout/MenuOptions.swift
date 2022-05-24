//
//  MenuOptions.swift
//  SiKNodeGraphEditor3
//
//  Created by Sinan Karasu on 1/19/22.
//

import SwiftUI

class MenuOptions {
    func setupOptions() -> [FlyoutMenuOption] {
        let flyoutMenuOptions = [
            FlyoutMenuOption(image: Image(systemName: "trash"), color: .blue,
                             action: {
                                 print("Trash")
                                 //self.cellData.delete(cell: self.node)
                             }),
            FlyoutMenuOption(image: Image(systemName: "square.on.circle"), color: .green,
                             action: {
                                 print("Modal")
                                 //self.modalViews.showShapes = true
                             }),
            FlyoutMenuOption(image: Image(systemName: "link"), color: .blue),
            //FlyoutMenuView.FlyoutMenuOption(image: Self.crayonImage, color: .orange)
            FlyoutMenuOption(image: Image(systemName: "pencil"), color: .orange)
        ]
        return flyoutMenuOptions
    }
}
