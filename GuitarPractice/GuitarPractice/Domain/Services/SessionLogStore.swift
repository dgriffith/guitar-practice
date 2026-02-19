import Foundation

class SessionLogStore {
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func save(_ log: SessionLog) throws {
        let dir = logsDirectory()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let dateStr = Self.fileDateFormatter.string(from: log.completedAt)
        let routineSlug = log.routineName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
        let shortId = log.id.uuidString.prefix(8).lowercased()
        let filename = "\(dateStr)_\(routineSlug)_\(shortId).json"

        let fileURL = dir.appendingPathComponent(filename)
        let data = try encoder.encode(log)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadAll() -> [SessionLog] {
        let dir = logsDirectory()
        guard FileManager.default.fileExists(atPath: dir.path) else { return [] }

        do {
            let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            return urls.compactMap { url in
                do {
                    let data = try Data(contentsOf: url)
                    return try decoder.decode(SessionLog.self, from: data)
                } catch {
                    print("Failed to decode session log \(url.lastPathComponent): \(error)")
                    return nil
                }
            }
            .sorted { $0.completedAt > $1.completedAt }
        } catch {
            print("Failed to load session logs: \(error)")
            return []
        }
    }

    func delete(_ log: SessionLog) throws {
        let dir = logsDirectory()
        guard FileManager.default.fileExists(atPath: dir.path) else { return }

        let urls = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }

        for url in urls {
            if let data = try? Data(contentsOf: url),
               let decoded = try? decoder.decode(SessionLog.self, from: data),
               decoded.id == log.id {
                try FileManager.default.removeItem(at: url)
                return
            }
        }
    }

    private func logsDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("GuitarPractice/SessionLogs", isDirectory: true)
    }

    private static let fileDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
