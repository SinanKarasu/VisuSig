import Foundation

/// An open, serializable discriminator for content carried by a visual node.
///
/// `PayloadKind` is deliberately a string value rather than an enum. New
/// domains can add kinds without changing VisualMesh or teaching it another
/// framework-specific case.
struct PayloadKind: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let generic = PayloadKind(rawValue: "visusig.generic")
    static let atlasStatement = PayloadKind(rawValue: "atlas.apply-statement")
    static let appleAudioUnit = PayloadKind(rawValue: "apple.audio-unit")
    static let audioFilePlayer = PayloadKind(rawValue: "apple.audio-file-player")
    static let audioOutput = PayloadKind(rawValue: "apple.audio-output")
    static let midiInput = PayloadKind(rawValue: "apple.midi-input")
}

/// One inspectable value in a payload. Fields are intentionally textual in
/// this first cut so they can round-trip through a spreadsheet, JSON, or a
/// future interchange format without importing a domain framework.
struct PayloadField: Identifiable, Codable, Hashable, Sendable {
    var id: String { key }

    let key: String
    var label: String
    var value: String

    init(_ key: String, label: String? = nil, value: String) {
        self.key = key
        self.label = label ?? key
        self.value = value
    }
}

/// Domain-neutral content carried by a node.
///
/// This is the durable model. A live implementation object (for example an
/// `AUManagedUnit`) belongs in `PayloadRuntimeStore`, keyed by this payload's
/// identity, and is never encoded into the graph.
struct Payload: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var kind: PayloadKind
    var title: String
    var fields: [PayloadField]

    init(id: UUID = UUID(),
         kind: PayloadKind = .generic,
         title: String,
         fields: [PayloadField] = []) {
        self.id = id
        self.kind = kind
        self.title = title
        self.fields = fields
    }

    subscript(field key: String) -> String? {
        get { fields.first(where: { $0.key == key })?.value }
        set {
            if let index = fields.firstIndex(where: { $0.key == key }) {
                if let newValue {
                    fields[index].value = newValue
                } else {
                    fields.remove(at: index)
                }
            } else if let newValue {
                fields.append(PayloadField(key, value: newValue))
            }
        }
    }
}

/// Ephemeral host objects associated with durable payloads.
///
/// VisualMesh knows only that a runtime adapter is an object. The Audio Unit
/// host, a future Resource Manager, or another domain asks for its own concrete
/// type at the boundary.
final class PayloadRuntimeStore {
    private var runtimes: [UUID: AnyObject] = [:]

    func register<Runtime: AnyObject>(_ runtime: Runtime, for payloadID: UUID) {
        runtimes[payloadID] = runtime
    }

    func runtime<Runtime: AnyObject>(for payloadID: UUID,
                                     as type: Runtime.Type = Runtime.self) -> Runtime? {
        runtimes[payloadID] as? Runtime
    }

    func removeRuntime(for payloadID: UUID) {
        runtimes.removeValue(forKey: payloadID)
    }
}
