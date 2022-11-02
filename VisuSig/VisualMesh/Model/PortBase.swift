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


class PortBase: Identifiable, Equatable, Hashable, Codable {
    enum CodingKeys: CodingKey {
        case id
        case offset
        case node
        case name
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        node = try container.decode(NodeBase.self, forKey: .node)
        // offset = try container.decode(CGPoint.self, forKey: .offset)
        name = try container.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(node, forKey: .node)
        // try container.encode(offset, forKey: .offset)
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
    let direction: Directions = .down
    var offset: CGSize {
        let portCount = Double(node.ports.count)
        let myIndex = Double(node.ports.firstIndex(of: self)!)
        let portleftMost = -(portCount - 1) / 2
        let delta = portleftMost + myIndex
        // print("\(portCount) \(myIndex) \(portleftMost) \(delta)")

        return CGSize(width: size.width * delta, height: node.size.height / 2 + size.height / 2)
    }
    //    let width: CGFloat  = 20
    //    let height: CGFloat = 40
    var name: String


    init(node: NodeBase, name: String = "Unknown") {
        self.node = node
        self.name = name
    }

    let defaultSize = CGSize(width: 100, height: 100)
}

extension PortBase {
    var position: CGPoint {
        return node.position.translatedBy(x: offset.width, y: offset.height)
    }

    var x: CGFloat {
        position.x
    }

    var y: CGFloat {
        position.x
    }
}

extension PortBase {
    var portInfo: some View {
        VStack {
            // Text(nameAndMFG)
            Text(String(format: "%.2f", position.x) + ":" + String(format: "%.2f", position.y))
            // Text("Port Count:\(ports.count)")
        }.padding([.top, .leading], 10)
    }

    var size: CGSize {
        CGSize(width: defaultSize.width, height: defaultSize.height)
    }

//    var width: CGFloat {
//        return 20
//    }
//
//    var height: CGFloat {
//        return 20
//    }
}


extension PortBase {
    func transformedAndScaledPort( parent: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
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
