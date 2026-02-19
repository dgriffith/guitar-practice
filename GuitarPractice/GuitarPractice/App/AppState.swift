import SwiftUI
import Observation

@Observable
class AppState {
    var selectedRoutine: PracticeRoutine?
    var activeSession: SessionViewModel?

    private let routineLoader = RoutineLoader()

    var isSessionActive: Bool { activeSession != nil }

    func startSession(for routine: PracticeRoutine) {
        activeSession = SessionViewModel(routine: routine)
        activeSession?.start()
    }

    func endSession() {
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
}
