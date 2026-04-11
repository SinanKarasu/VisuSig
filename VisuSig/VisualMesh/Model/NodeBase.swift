import SwiftUI
import AVFoundation

enum NodeRole: String, Codable {
    case source   // Audio file player — feeds the chain
    case effect   // AU effect processor
    case output   // Final output (hardware)
    case generic  // Unlabelled / demo node
}

@Observable
class NodeBase: Identifiable {
    let id = UUID()
    var text: String = "Node"
    var position: CGPoint = .zero
    var ports = [PortBase]()
    var payload: AUManagedUnit?
    var nodeRole: NodeRole = .generic

    init(text: String = "", position: CGPoint = .zero, payload: AUManagedUnit?, role: NodeRole = .generic) {
        self.position = position
        self.text = text
        self.payload = payload
        self.nodeRole = role
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        position = try container.decode(CGPoint.self, forKey: .position)
        nodeRole = (try? container.decode(NodeRole.self, forKey: .nodeRole)) ?? .generic
    }

    let defaultSize = CGSize(width: 180, height: 60)
}

extension NodeBase: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension NodeBase: Equatable {
    static func == (lhs: NodeBase, rhs: NodeBase) -> Bool {
        lhs.id == rhs.id
    }
}

extension NodeBase: Codable {
    enum CodingKeys: CodingKey {
        case id
        case position
        case text
        case nodeRole
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(position, forKey: .position)
        try container.encode(nodeRole, forKey: .nodeRole)
    }
}

// MARK: - Port helpers

extension NodeBase {
    var inputPorts: [PortBase] { ports.filter { $0.portType == .input } }
    var outputPorts: [PortBase] { ports.filter { $0.portType == .output } }

    /// Height of the tallest port (0 if no ports)
    var portAreaHeight: CGFloat {
        ports.max { $0.size.height < $1.size.height }?.size.height ?? 0
    }

    @discardableResult
    func addPort(port: PortBase) -> NodeBase {
        ports.append(port)
        return self
    }
}

// MARK: - Size & layout

extension NodeBase {
    var size: CGSize {
        let portWidth: CGFloat = 40   // each port column width
        let maxPortCount = CGFloat(max(inputPorts.count, outputPorts.count, 1))
        let minWidth = maxPortCount * portWidth + 60
        return CGSize(width: max(defaultSize.width, minWidth), height: defaultSize.height)
    }

    func transformedAndScaledNode(parent: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
        position
            .scaledFrom(zoomScale)
            .alignCenterInParent(parent)
            .translatedBy(x: portalPosition.x, y: portalPosition.y)
    }
}

// MARK: - Node info view

extension NodeBase {
    var nodeInfo: some View {
        VStack(spacing: 2) {
            Text(displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if nodeRole == .generic {
                Text(String(format: "%.0f, %.0f", position.x, position.y))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 8)
    }

    private var displayName: String {
        switch nodeRole {
        case .source: return "🎵 " + (text.isEmpty ? "Audio Source" : text)
        case .output: return "🔊 Output"
        case .effect: return payload?.name ?? text
        case .generic: return text.isEmpty ? "Node" : text
        }
    }
}

// MARK: - AVAudio helpers

extension NodeBase {
    var avAudioUnit: AVAudioUnit? {
        payload?.avAudioUnit
    }

    var visualID: String {
        return id.uuidString + "\(text.hashValue)\(nodeRole.rawValue)"
    }
}
