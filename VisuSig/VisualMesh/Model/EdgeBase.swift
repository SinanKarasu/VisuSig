
import Foundation
import CoreGraphics

class EdgeBase: Identifiable, ObservableObject {
    var id = UUID()
    @Published var startPort: PortBase
    @Published var endPort: PortBase

    @Published var data : CubicBezierData?

    init(start:PortBase, end:PortBase, data: CubicBezierData? = nil) {
        self.startPort = start
        self.endPort = end
        self.data = CubicBezierData(edge: self)
    }

    enum CodingKeys: CodingKey {
        case id
        case startPort
        case endPort
        case data
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startPort = try container.decode(PortBase.self, forKey: .startPort)
        endPort = try container.decode(PortBase.self, forKey: .endPort)
        data = CubicBezierData(edge: self)
    }

}


extension EdgeBase : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

extension EdgeBase: Equatable {
    static func == (lhs: EdgeBase, rhs: EdgeBase) -> Bool {
        return lhs.startPort == rhs.startPort && lhs.endPort == rhs.endPort
    }
}

extension EdgeBase:Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startPort, forKey: .startPort)
        try container.encode(endPort, forKey: .endPort)
    }
}
