//
//  SystemIcon.swift
//  RetroDock
//
//  Created by Sinan Karasu on 5/21/22.
//

import SwiftUI


func SystemIcon(forURL url: String) -> Image? {
    guard let icon =
            NSWorkspace.shared.icon(forFile: url.replacingOccurrences(of: "file://", with: ""))
            .representations
            .first(where: { $0.size.width > 150 })?
            .cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }
    let nsImage = NSImage(cgImage: icon, size: CGSize(width: icon.width, height: icon.height))
    return Image(nsImage: nsImage)
}

