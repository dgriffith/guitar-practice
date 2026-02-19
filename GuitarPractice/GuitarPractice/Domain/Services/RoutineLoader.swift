import Foundation

class RoutineLoader {
    func loadAllRoutines() -> [PracticeRoutine] {
        var routines = loadBundledRoutines()
        routines.append(contentsOf: loadUserRoutines())
        routines.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return routines
    }

    func loadBundledRoutines() -> [PracticeRoutine] {
        // Try subdirectory first (folder reference), then flat bundle (group)
        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "Routines"), !urls.isEmpty {
            return urls.compactMap { loadRoutine(from: $0) }
        }
        // Fallback: JSON files copied flat into bundle Resources
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            return []
        }
        return urls.compactMap { loadRoutine(from: $0) }
    }

    func loadUserRoutines() -> [PracticeRoutine] {
        let userDir = userRoutinesDirectory()
        guard FileManager.default.fileExists(atPath: userDir.path) else { return [] }

        do {
            let urls = try FileManager.default.contentsOfDirectory(at: userDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            return urls.compactMap { loadRoutine(from: $0) }
        } catch {
            print("Failed to load user routines: \(error)")
            return []
        }
    }

    func saveRoutine(_ routine: PracticeRoutine) throws {
        let userDir = userRoutinesDirectory()
        try FileManager.default.createDirectory(at: userDir, withIntermediateDirectories: true)

        let filename = routine.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
        let fileURL = userDir.appendingPathComponent("\(filename).json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(routine)
        try data.write(to: fileURL, options: .atomic)
    }

    private func loadRoutine(from url: URL) -> PracticeRoutine? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PracticeRoutine.self, from: data)
        } catch {
            print("Failed to decode \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    private func userRoutinesDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("GuitarPractice/Routines", isDirectory: true)
    }
}
