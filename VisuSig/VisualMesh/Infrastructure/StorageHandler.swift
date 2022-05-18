
import AppKit

/// Encapsulates file ops for the mesh data
class StorageHandler {

    static func getDocumentsDirectory() -> URL {
        // find all possible documents directories for this user
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

        // just send back the first one, which ought to be the only one
        return paths[0]
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    /// save mesh data to a single file
    func save(_ mesh: MeshStorageProxy) throws {
        let data = try JSONEncoder().encode(mesh)
        let documentURL = getDocumentsDirectory()
        try data.write(to: documentURL)
    }

    func restore() -> MeshStorageProxy {
        do {
            let documentURL = getDocumentsDirectory()
            print("Document Directory:\(documentURL)")
            let data = try Data(contentsOf: documentURL)
            let proxy = try JSONDecoder().decode(MeshStorageProxy.self , from: data)
            return proxy
        } catch {
            DLog("*** oh no! restore error (pass to error system in full impl) -", error)
        }
        return Mesh().storageObject
    }

}
