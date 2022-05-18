
import Foundation
import CoreGraphics

class EdgeBase: Identifiable, ObservableObject, Equatable, Hashable {
    var id = UUID()
    @Published var startPort: PortBase
    @Published var endPort: PortBase

    @Published var data : CubicBezierData?

    init(start:PortBase, end:PortBase, data: CubicBezierData? = nil) {
        self.startPort = start
        self.endPort = end
        self.data = CubicBezierData(edge: self)
    }

//    init(data: CubicBezierData? ) {
//        self.startPort = data!.from
//        self.endPort = data!.to
//        self.data = data
//    }

    enum CodingKeys: CodingKey {
        case id
        case startPort
        case endPort
        case data
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(position.x)
//        hasher.combine(position.y)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startPort, forKey: .startPort)
        try container.encode(endPort, forKey: .endPort)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startPort = try container.decode(PortBase.self, forKey: .startPort)
        endPort = try container.decode(PortBase.self, forKey: .endPort)
        //data = try container.decode(CubicBezierData.self, forKey: .data)
        data = CubicBezierData(edge: self)

        //position = try container.decode(CGPoint.self, forKey: .position)
    }

}

struct EdgeProxy: Identifiable, Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id = UUID()
    var edge: EdgeBase
    init(edge: EdgeBase) {
        self.edge = edge
        //self.end = edge.end
    }
}

extension EdgeBase {
    static func == (lhs: EdgeBase, rhs: EdgeBase) -> Bool {
        return lhs.startPort == rhs.startPort && lhs.endPort == rhs.endPort
    }
}

extension EdgeBase:Codable {}
