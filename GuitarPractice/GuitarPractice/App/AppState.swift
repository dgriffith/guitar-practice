import SwiftUI
import Observation

@Observable
class AppState {
    var selectedRoutine: PracticeRoutine?
    var activeSession: SessionViewModel?
    var sessionLogs: [SessionLog] = []
    var selectedSessionLog: SessionLog?

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
}
