//
//  Port.swift
//  SiKNodeGraphEditor
//
//  Created by Sinan Karasu on 12/14/21.
//

import SwiftUI
import AVFoundation

enum Directions {
    case up
    case right
    case down
    case left
}

enum PortType: String, Codable {
    case input
    case output
}

class PortBase: Identifiable, Equatable, Hashable, Codable {
    enum CodingKeys: CodingKey {
        case id
        case node
        case name
        case portType
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        node = try container.decode(NodeBase.self, forKey: .node)
        name = try container.decode(String.self, forKey: .name)
        portType = (try? container.decode(PortType.self, forKey: .portType)) ?? .output
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(node, forKey: .node)
        try container.encode(name, forKey: .name)
        try container.encode(portType, forKey: .portType)
    }

    static func == (lhs: PortBase, rhs: PortBase) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(node)
    }

    let id = UUID()
    var node: NodeBase
    var portType: PortType = .output

    /// Offset from node center in mesh coordinates.
    /// Input ports appear above the node; output ports below.
    var offset: CGSize {
        let sameTypePorts = node.ports.filter { $0.portType == portType }
        let portCount = Double(sameTypePorts.count)
        let myIndex = Double(sameTypePorts.firstIndex(of: self) ?? 0)
        let portleftMost = -(portCount - 1) / 2.0
        let delta = portleftMost + myIndex

        let yOffset: CGFloat = portType == .input
            ? -(node.size.height / 2.0 + size.height / 2.0)
            :  (node.size.height / 2.0 + size.height / 2.0)

        return CGSize(width: size.width * delta, height: yOffset)
    }

    var name: String

    init(node: NodeBase, name: String = "Unknown", portType: PortType = .output) {
        self.node = node
        self.name = name
        self.portType = portType
    }

    let defaultSize = CGSize(width: 36, height: 36)
}

extension PortBase {
    var position: CGPoint {
        return node.position.translatedBy(x: offset.width, y: offset.height)
    }

    var x: CGFloat { position.x }
    var y: CGFloat { position.y }  // Fixed: was incorrectly returning position.x
}

extension PortBase {
    var portInfo: some View {
        VStack {
            Text(name)
                .font(.system(size: 9, weight: .medium))
        }
    }

    var size: CGSize {
        CGSize(width: defaultSize.width, height: defaultSize.height)
    }
}

extension PortBase {
    func transformedAndScaledPort(parent: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
        return position
            .scaledFrom(zoomScale)
            .alignCenterInParent(parent)
            .translatedBy(x: portalPosition.x, y: portalPosition.y)
    }
}

extension PortBase {
    var avAudioUnit: AVAudioUnit? {
        node.avAudioUnit
    }
}
