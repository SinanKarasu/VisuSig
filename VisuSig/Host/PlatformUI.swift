import AVFoundation
import SwiftUI

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
typealias PluginViewController = NSViewController
#else
import UIKit
typealias PlatformImage = UIImage
typealias PluginViewController = UIViewController
#endif

/// Keeps platform presentation choices out of the graph and session models.
enum PlatformUI {
    static var minimumWindowWidth: CGFloat? {
        #if os(macOS)
        1100
        #else
        nil
        #endif
    }

    static func desktopMinimum(_ width: CGFloat) -> CGFloat? {
        #if os(macOS)
        width
        #else
        nil
        #endif
    }

    static var controlBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemBackground)
        #endif
    }

    static var textBackground: Color {
        #if os(macOS)
        Color(nsColor: .textBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    static var separator: Color {
        #if os(macOS)
        Color(nsColor: .separatorColor)
        #else
        Color(uiColor: .separator)
        #endif
    }
}

struct WorkspaceSplitView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        #if os(macOS)
        HSplitView(content: content)
        #else
        HStack(spacing: 0, content: content)
        #endif
    }
}

/// iPadOS audio routing is mediated by AVAudioSession.
enum PlatformAudioSession {
    static func activate() throws {
        #if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        #endif
    }
}
