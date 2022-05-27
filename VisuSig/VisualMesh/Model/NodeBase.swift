
import SwiftUI
import CoreGraphics

class NodeBase: Identifiable, ObservableObject  {
    @Published var id = UUID()
    @Published var text: String = "Sick Root"
    @Published var position: CGPoint = .zero

    @Published var ports = [PortBase]()
    {
        willSet{
            objectWillChange.send()
        }
    }
    
    var payload: AUManagedUnit? = nil

    init( text: String = "", position: CGPoint = .zero) {
        self.position = position
        self.text = text
    }

    var visualID: String {
        return id.uuidString + "\(text.hashValue)"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        position = try container.decode(CGPoint.self, forKey: .position)
    }
    
    let defaultSize = CGSize(width: 200,height: 200)

}

extension NodeBase: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(position.x)
//        hasher.combine(position.y)
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
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(position, forKey: .position)
    }

    
}

extension NodeBase {
    var nodeInfo: some View {
        VStack {
            Text(text)
            Text(String(format:"%.2f",position.x)+":"+String(format:"%.2f",position.y))
            Text("Port Count:\(ports.count)")
        }.padding([.top, .leading], 10)
    }
}

extension NodeBase {
    var size: CGSize {
        CGSize(width: max(defaultSize.width, CGFloat(Double(ports.count)*30.0)), height: defaultSize.height)
    }

    @discardableResult
    func addPort(port: PortBase) -> NodeBase {
        ports.append(port)
        return self
    }
}

extension NodeBase {
    var portAreaHeight: CGFloat {
        return ports.max { $0.size.height < $1.size.height}!.size.height
    }
}


extension NodeBase {
    func transformedAndScaledNode( parent: CGSize, portalPosition: CGPoint, zoomScale: CGFloat) -> CGPoint {
        position
        .scaledFrom(zoomScale)
        .alignCenterInParent(parent)
        .translatedBy(x: portalPosition.x, y: portalPosition.y)
    }

}
