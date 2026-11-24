import CryptoKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import VisualMesh

extension UTType {
    // The broad audio category also includes MIDI and karaoke documents.
    static let sampledAudioFileTypes: [UTType] = [
        "wav", "aiff", "caf", "m4a", "mp3", "aac", "flac"
    ].compactMap { UTType(filenameExtension: $0) }

    static let visuSigProject = UTType(exportedAs: "org.bozuk.sinan.visusig-project", conformingTo: .package)
}

/// Versioned music-document records. Runtime graphs are supplied by VisualMesh.
struct MusicSessionDocument: Codable {
    struct Node: Codable {
        var id: UUID
        var title: String
        var payload: Payload
        var ports: [GraphPort]
        var subgraph: GraphSubgraphInstance?
        var x: Double
        var y: Double
        var plugin: Plugin?
    }

    struct Plugin: Codable {
        var type: UInt32
        var subtype: UInt32
        var manufacturer: UInt32
        var version: UInt32
        var statePath: String?
    }

    struct Connection: Codable {
        var id: UUID
        var source: GraphEndpoint
        var target: GraphEndpoint
        var settings: AudioConnection
    }

    var nodes: [Node]
    var connections: [Connection]
    var audioAssetID: UUID?
}

struct ProjectManifest: Codable {
    struct Asset: Codable {
        var id: UUID
        var originalName: String
        var path: String
        var sha256: String
    }

    var schemaVersion = 1
    var documentKind = "musicSession"
    var assets: [Asset] = []
}

enum SessionPackageError: LocalizedError {
    case invalid(String)

    var errorDescription: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

/// Owns collected media even before the user first saves the project.
/// An opened project is copied here so failed imports cannot modify its source.
final class SessionPackage {
    let root: URL
    private(set) var manifest: ProjectManifest

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VisuSig-" + UUID().uuidString + ".visusig", isDirectory: true)
        manifest = ProjectManifest()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    init(opening url: URL) throws {
        let manifestURL = try Self.containedURL("Manifest.json", in: url)
        manifest = try JSONDecoder().decode(ProjectManifest.self, from: Data(contentsOf: manifestURL))
        guard manifest.schemaVersion == 1, manifest.documentKind == "musicSession" else {
            throw SessionPackageError.invalid("This project kind or schema version is not supported.")
        }
        guard Set(manifest.assets.map(\.id)).count == manifest.assets.count else {
            throw SessionPackageError.invalid("The project contains duplicate asset identities.")
        }
        for asset in manifest.assets {
            guard asset.path.hasPrefix("Media/") else {
                throw SessionPackageError.invalid("Project media must be inside the Media folder.")
            }
            let assetURL = try Self.containedURL(asset.path, in: url)
            guard try Self.hash(assetURL) == asset.sha256 else {
                throw SessionPackageError.invalid("A collected media file is damaged or has changed: " + asset.originalName)
            }
        }
        _ = try Self.containedURL("Session.json", in: url)
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("VisuSig-" + UUID().uuidString + ".visusig", isDirectory: true)
        do {
            try FileManager.default.copyItem(at: url.resolvingSymlinksInPath(), to: root)
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }

    deinit { try? FileManager.default.removeItem(at: root) }

    static func containedURL(_ path: String, in root: URL) throws -> URL {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !path.isEmpty, !path.hasPrefix("/"),
              !components.contains(where: { $0 == ".." || $0 == "." || $0.isEmpty }) else {
            throw SessionPackageError.invalid("The project contains an invalid internal path.")
        }
        // Resolve the existing root once. Resolving a not-yet-created child
        // independently can produce a different /var vs /private/var spelling
        // on iPadOS, falsely reporting that an internal save path escapes.
        let resolvedRoot = root.resolvingSymlinksInPath().standardizedFileURL
        var prefix = resolvedRoot
        for component in components {
            prefix.appendPathComponent(String(component))
            if (try? FileManager.default.destinationOfSymbolicLink(atPath: prefix.path)) != nil {
                throw SessionPackageError.invalid("Project resources cannot be symbolic links.")
            }
        }
        // Each appended component is validated and each existing descendant
        // is checked for symlinks. Build future paths from that same root
        // without independently canonicalizing a nonexistent file.
        return prefix
    }

    func url(for assetID: UUID) throws -> URL {
        guard let asset = manifest.assets.first(where: { $0.id == assetID }) else {
            throw SessionPackageError.invalid("The project's audio asset is missing from its manifest.")
        }
        return try Self.containedURL(asset.path, in: root)
    }

    func assetName(_ id: UUID) -> String? {
        manifest.assets.first { $0.id == id }?.originalName
    }

    /// Copy first, then hash the owned copy. External edits cannot change the
    /// bytes we validate or introduce a race between hashing and collection.
    func collect(_ source: URL) throws -> ProjectManifest.Asset {
        let folder = root.appendingPathComponent("Media/Audio", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let candidate = folder.appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(source.pathExtension)
        let resolvedSource = source.resolvingSymlinksInPath()
        guard try resolvedSource.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true else {
            throw SessionPackageError.invalid("Only regular media files can be imported.")
        }
        try FileManager.default.copyItem(at: resolvedSource, to: candidate)
        do {
            let digest = try Self.hash(candidate)
            if let existing = manifest.assets.first(where: { $0.sha256 == digest }) {
                try FileManager.default.removeItem(at: candidate)
                return existing
            }
            let asset = ProjectManifest.Asset(
                id: UUID(), originalName: source.lastPathComponent,
                path: "Media/Audio/" + candidate.lastPathComponent, sha256: digest
            )
            manifest.assets.append(asset)
            return asset
        } catch {
            try? FileManager.default.removeItem(at: candidate)
            throw error
        }
    }

    static func hash(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let bytes = try handle.read(upToCount: 1_048_576), !bytes.isEmpty {
            hasher.update(data: bytes)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func readSession() throws -> MusicSessionDocument {
        let url = try Self.containedURL("Session.json", in: root)
        return try JSONDecoder().decode(MusicSessionDocument.self, from: Data(contentsOf: url))
    }

    func writeJSON<T: Encodable>(_ value: T, path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = try Self.containedURL(path, in: root)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(value).write(to: url, options: .atomic)
    }

    func save(_ session: MusicSessionDocument, to destination: URL) throws {
        try writeJSON(manifest, path: "Manifest.json")
        try writeJSON(session, path: "Session.json")

        // Stage on the destination volume, then atomically replace the package.
        // Keep the old package intact if collecting or encoding anything fails.
        let manager = FileManager.default
        let staging = destination.deletingLastPathComponent()
            .appendingPathComponent("." + UUID().uuidString + ".visusig", isDirectory: true)
        defer { try? manager.removeItem(at: staging) }
        try manager.copyItem(at: root, to: staging)
        if manager.fileExists(atPath: destination.path) {
            _ = try manager.replaceItemAt(destination, withItemAt: staging)
        } else {
            try manager.moveItem(at: staging, to: destination)
        }
    }
}

enum MusicProjectAction: Hashable {
    case open, save, saveAs
}

struct MusicProjectActions {
    var open: () -> Void
    var save: () -> Void
    var saveAs: () -> Void
}

private struct MusicProjectActionsKey: FocusedValueKey {
    typealias Value = MusicProjectActions
}

extension FocusedValues {
    var musicProjectActions: MusicProjectActions? {
        get { self[MusicProjectActionsKey.self] }
        set { self[MusicProjectActionsKey.self] = newValue }
    }
}

struct MusicProjectCommands: Commands {
    @FocusedValue(\.musicProjectActions) private var actions

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Music Project…") { actions?.open() }
                .keyboardShortcut("o")
                .disabled(actions == nil)
            Button("Save Music Project") { actions?.save() }
                .keyboardShortcut("s")
                .disabled(actions == nil)
            Button("Save Music Project As…") { actions?.saveAs() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(actions == nil)
        }
    }
}


#if !os(macOS)
struct MusicProjectExport: FileDocument {
    static var readableContentTypes: [UTType] { [.visuSigProject] }
    private let representation: Data

    init(url: URL) throws {
        let wrapper = try FileWrapper(url: url, options: .immediate)
        guard let data = wrapper.serializedRepresentation else {
            throw SessionPackageError.invalid("The project could not be prepared for export.")
        }
        representation = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.serializedRepresentation else {
            throw SessionPackageError.invalid("The project could not be read.")
        }
        representation = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let wrapper = FileWrapper(serializedRepresentation: representation) else {
            throw SessionPackageError.invalid("The project could not be exported.")
        }
        return wrapper
    }
}
#endif
