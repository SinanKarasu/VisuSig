import AVFoundation
import Foundation
import VisualMesh

@main
struct MusicProjectChecks {
    @MainActor
    static func main() async throws {
        let manager = FileManager.default
        let folder = manager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: folder) }

        // A real, independently decodable audio file exercises media collection.
        let source = folder.appendingPathComponent("Original.wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        do {
            let file = try AVAudioFile(forWriting: source, settings: format.settings)
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 128)!
            buffer.frameLength = 128
            for index in 0..<128 { buffer.floatChannelData![0][index] = 0.01 }
            try file.write(from: buffer)
        }

        let graph = AudioGraph.makeDefault()
        precondition(graph.loadAudioFile(url: source))
        let owned = graph.audioFileURL!
        precondition(owned != source)
        let originalBytes = try Data(contentsOf: source)
        let ownedBytes = try Data(contentsOf: owned)
        precondition(originalBytes == ownedBytes)
        try manager.removeItem(at: source)
        precondition(manager.fileExists(atPath: owned.path))

        let input = graph.mesh.nodes.first { graph.role(of: $0) == .source }!
        let mixer = graph.mesh.nodes.first { graph.role(of: $0) == .mixer }!
        graph.layout.setPosition(CGPoint(x: 123, y: -456), for: input.id)
        let edge = try graph.mesh.connect(
            sourceNodeID: input.id, sourcePortID: input.ports[0].id,
            targetNodeID: mixer.id, targetPortID: mixer.ports[0].id,
            payload: AudioConnection()
        )
        edge.payload.volume = 0.37
        edge.payload.pan = -0.4
        edge.payload.isMuted = true
        graph.masterVolume = 0.6

        let destination = folder.appendingPathComponent("Session.visusig", isDirectory: true)
        try graph.saveProject(to: destination)
        // Atomic overwrite must work for package directories as well as first saves.
        try graph.saveProject(to: destination)
        let moved = folder.appendingPathComponent("Moved.visusig", isDirectory: true)
        try manager.moveItem(at: destination, to: moved)
        let reopened = try await AudioGraph.openProject(at: moved)
        precondition(reopened.mesh.nodes.map(\.id) == graph.mesh.nodes.map(\.id))
        precondition(reopened.layout.position(of: input.id) == CGPoint(x: 123, y: -456))
        precondition(abs(reopened.masterVolume - 0.6) < 0.0001)
        precondition(reopened.audioFile != nil && reopened.audioFileName == "Original.wav")
        let restored = reopened.mesh.edges.first { $0.sourceNodeID == input.id }!
        precondition(restored.payload.isMuted && restored.payload.volume == 0.37 && restored.payload.pan == -0.4)

        let savedAgain = folder.appendingPathComponent("SavedAgain.visusig")
        try reopened.saveProject(to: savedAgain)
        let firstDocument = try SessionPackage(opening: moved).readSession()
        let secondDocument = try SessionPackage(opening: savedAgain).readSession()
        precondition(firstDocument.connections.map(\.id) == secondDocument.connections.map(\.id))

        // Same bytes with another name deduplicate; different bytes with the
        // same basename remain separate assets.
        let collection = try SessionPackage()
        let first = try collection.collect(owned)
        let duplicate = try collection.collect(owned)
        precondition(first.id == duplicate.id && collection.manifest.assets.count == 1)
        let other = folder.appendingPathComponent(owned.lastPathComponent)
        try Data("different contents".utf8).write(to: other)
        let distinct = try collection.collect(other)
        precondition(distinct.id != first.id && collection.manifest.assets.count == 2)

        // Future schemas and escaping paths must fail before replacing a session.
        for path in ["../Outside.wav", "/tmp/Outside.wav", "Media/../Outside.wav"] {
            do {
                _ = try SessionPackage.containedURL(path, in: collection.root)
                preconditionFailure("Accepted an escaping path")
            } catch {}
        }
        // A package root may itself be reached through a system/path alias.
        // New state directories must be writable before their children exist.
        let alias = folder.appendingPathComponent("PackageAlias.visusig")
        try manager.createSymbolicLink(at: alias, withDestinationURL: collection.root)
        let futureState = try SessionPackage.containedURL("PluginStates/new.plist", in: alias)
        try manager.createDirectory(at: futureState.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("state".utf8).write(to: futureState)
        precondition(manager.fileExists(atPath: collection.root.appendingPathComponent("PluginStates/new.plist").path))

        let link = collection.root.appendingPathComponent("Outside")
        try manager.createSymbolicLink(at: link, withDestinationURL: folder)
        do {
            _ = try SessionPackage.containedURL("Outside/Original.wav", in: collection.root)
            preconditionFailure("Accepted an escaping symlink")
        } catch {}

        let manifest = moved.appendingPathComponent("Manifest.json")
        var invalid = try JSONDecoder().decode(ProjectManifest.self, from: Data(contentsOf: manifest))
        invalid.schemaVersion = 999
        try JSONEncoder().encode(invalid).write(to: manifest)
        do {
            _ = try await AudioGraph.openProject(at: moved)
            preconditionFailure("Accepted a future schema")
        } catch {}

        // Round-trip a real Audio Unit state and bypass setting.
        let descriptor = AudioComponentDescription(
            componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_LowPassFilter,
            componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0
        )
        let avUnit = try await AVAudioUnit.instantiate(with: descriptor)
        let component = AVAudioUnitComponentManager.shared().components(matching: descriptor).first!
        let managed = AUManagedUnit(protoType: Component(component, type: .effect),
                                    audioUnit: avUnit, audioUnitType: .effect, icon: nil)
        let pluginGraph = AudioGraph.makeDefault()
        pluginGraph.addPlugin(managed, at: .zero)
        let pluginNode = pluginGraph.mesh.nodes.first { $0.payload.kind == .appleAudioUnit }!
        let parameter = avUnit.auAudioUnit.parameterTree!.allParameters.first!
        parameter.value = parameter.minValue + (parameter.maxValue - parameter.minValue) * 0.3
        let expectedValue = parameter.value
        pluginGraph.togglePluginPower(pluginNode.id)
        let pluginProject = folder.appendingPathComponent("Plugin.visusig")
        try pluginGraph.saveProject(to: pluginProject)
        let pluginRestored = try await AudioGraph.openProject(at: pluginProject)
        precondition(pluginRestored.projectWarnings.isEmpty)
        let restoredNode = pluginRestored.mesh.node(id: pluginNode.id)!
        let restoredUnit = pluginRestored.managedAudioUnit(for: restoredNode)!.audioUnit!
        precondition(restoredUnit.shouldBypassEffect)
        precondition(abs(restoredUnit.parameterTree!.parameter(withAddress: parameter.address)!.value - expectedValue) < 0.1)

        // Unavailable components retain their exact state reference through save.
        let missingPackage = try SessionPackage(opening: pluginProject)
        var missingDocument = try missingPackage.readSession()
        let pluginIndex = missingDocument.nodes.firstIndex { $0.plugin != nil }!
        missingDocument.nodes[pluginIndex].plugin!.manufacturer = 0x5A5A5A5A
        let missingProject = folder.appendingPathComponent("Missing.visusig")
        try missingPackage.save(missingDocument, to: missingProject)
        let missingRestored = try await AudioGraph.openProject(at: missingProject)
        precondition(missingRestored.projectWarnings.count == 1)
        let preservedProject = folder.appendingPathComponent("Preserved.visusig")
        try missingRestored.saveProject(to: preservedProject)
        let preservedPackage = try SessionPackage(opening: preservedProject)
        let preservedDocument = try preservedPackage.readSession()
        let originalState = missingDocument.nodes[pluginIndex].plugin!.statePath!
        let preservedState = preservedDocument.nodes[pluginIndex].plugin!.statePath!
        let originalStateBytes = try Data(contentsOf: missingPackage.root.appendingPathComponent(originalState))
        let preservedStateBytes = try Data(contentsOf: preservedPackage.root.appendingPathComponent(preservedState))
        precondition(originalStateBytes == preservedStateBytes)

        print("Music project checks passed")
    }
}
