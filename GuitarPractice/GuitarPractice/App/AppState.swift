import AppKit
import SwiftUI
import Observation

@Observable
class AppState {
    var selectedRoutine: PracticeRoutine?
    var activeSession: SessionViewModel?
    var sessionLogs: [SessionLog] = []
    var selectedSessionLog: SessionLog?
    var importError: String?

    private let routineLoader = RoutineLoader()
    private let sessionLogStore = SessionLogStore()

    var isSessionActive: Bool { activeSession != nil }

    func startSession(for routine: PracticeRoutine) {
        activeSession = SessionViewModel(routine: routine)
        activeSession?.start()
    }

    func endSession() {
        if let session = activeSession, session.state == .completed {
            let log = session.buildSessionLog()
            do {
                try sessionLogStore.save(log)
                sessionLogs.insert(log, at: 0)
            } catch {
                print("Failed to save session log: \(error)")
            }
        }
        activeSession?.cleanup()
        activeSession = nil
    }

    func saveRoutine(_ routine: PracticeRoutine) {
        do {
            try routineLoader.saveRoutine(routine)
        } catch {
            print("Failed to save routine: \(error)")
        }
    }

    func loadSessionLogs() {
        sessionLogs = sessionLogStore.loadAll()
    }

    func deleteSessionLog(_ log: SessionLog) {
        do {
            try sessionLogStore.delete(log)
            sessionLogs.removeAll { $0.id == log.id }
            if selectedSessionLog?.id == log.id {
                selectedSessionLog = nil
            }
        } catch {
            print("Failed to delete session log: \(error)")
        }
    }

    // MARK: - Import / Export

    func exportRoutine(_ routine: PracticeRoutine) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = routine.name
            .replacingOccurrences(of: " ", with: "-")
            .lowercased() + ".json"
        panel.title = "Export Routine"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try routineLoader.exportRoutine(routine, to: url)
        } catch {
            importError = "Failed to export: \(error.localizedDescription)"
        }
    }

    func showImportPanel(onComplete: @escaping () -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = true
        panel.title = "Import Routines"
        panel.message = "Select one or more routine JSON files"

        guard panel.runModal() == .OK else { return }
        importRoutines(from: panel.urls, onComplete: onComplete)
    }

    func importRoutines(from urls: [URL], onComplete: (() -> Void)? = nil) {
        var importedCount = 0
        var errors: [String] = []

        for url in urls {
            // Gain access to security-scoped resources from drag-and-drop
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                _ = try routineLoader.importRoutine(from: url)
                importedCount += 1
            } catch {
                errors.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if !errors.isEmpty {
            importError = "Failed to import \(errors.count) file\(errors.count == 1 ? "" : "s"):\n\(errors.joined(separator: "\n"))"
        }

        if importedCount > 0 {
            onComplete?()
        }
    }
}
