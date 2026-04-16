import AppKit

/// Encapsulates file ops for the mesh data
class StorageHandler {
    static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// save mesh data to a single file
    func save(_ mesh: MeshStorageProxy) throws {
        let data = try JSONEncoder().encode(mesh)
        let documentURL = StorageHandler.getDocumentsDirectory()
        try data.write(to: documentURL)
    }

    func restore() -> MeshStorageProxy {
        do {
            let documentURL = StorageHandler.getDocumentsDirectory()
            print("Document Directory:\(documentURL)")
            let data = try Data(contentsOf: documentURL)
            let proxy = try JSONDecoder().decode(MeshStorageProxy.self, from: data)
            return proxy
        } catch {
            DLog("*** oh no! restore error (pass to error system in full impl) -", error)
        }
        return Mesh().storageObject
    }
}
