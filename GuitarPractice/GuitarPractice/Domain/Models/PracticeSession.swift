import Foundation
import Observation

// MARK: - SessionState

enum SessionState: Equatable {
    case ready
    case countdown(remaining: Int)
    case playing
    case paused
    case stepComplete
    case completed
}

// MARK: - PracticeSession

@Observable
class PracticeSession {
    let routine: PracticeRoutine
    var displaySteps: [PracticeStep]

    var currentStepIndex: Int = 0
    var stepElapsedTime: TimeInterval = 0
    var sessionElapsedTime: TimeInterval = 0
    var state: SessionState = .ready
    var currentBeat: Int = 0
    var currentMeasure: Int = 1

    var currentStep: PracticeStep {
        displaySteps[currentStepIndex]
    }

    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex == displaySteps.count - 1 }
    var stepsCompleted: Int { currentStepIndex }
    var totalSteps: Int { displaySteps.count }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }

    var stepTimeRemaining: TimeInterval? {
        guard let duration = currentStep.duration else { return nil }
        return max(0, duration - stepElapsedTime)
    }

    init(routine: PracticeRoutine) {
        self.routine = routine
        self.displaySteps = routine.steps
    }
}
