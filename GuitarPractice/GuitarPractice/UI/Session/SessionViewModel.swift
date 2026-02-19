import Foundation
import Observation

@Observable
class SessionViewModel {
    let session: PracticeSession
    private let metronome: MetronomeEngine
    private let soundPlayer: SoundPlayer
    private let speechRecognizer: SpeechRecognizer
    private var timer: Timer?

    /// BPM overrides per step index. Only contains entries for steps the user adjusted.
    private(set) var bpmOverrides: [Int: Int] = [:]

    // MARK: - Voice State

    private(set) var lastVoiceCommand: VoiceCommand?
    private(set) var lastVoiceCommandTime: Date?
    var isVoiceActive: Bool { speechRecognizer.isListening }
    var isVoiceAvailable: Bool { speechRecognizer.isAvailable }

    // MARK: - Derived State

    var stepName: String { session.currentStep.name }
    var instructions: String { session.currentStep.instructions }
    var notes: String? { session.currentStep.notes }
    var isTimed: Bool { session.currentStep.isTimed }
    var isMetronomeActive: Bool { session.currentStep.hasMetronome }
    var canGoBack: Bool { !session.isFirstStep }
    var isLastStep: Bool { session.isLastStep }
    var state: SessionState { session.state }
    var routineName: String { session.routine.name }
    var steps: [PracticeStep] { session.routine.steps }
    var currentStepIndex: Int { session.currentStepIndex }

    var hasBPMChanges: Bool { !bpmOverrides.isEmpty }

    var timeDisplay: String {
        if isTimed {
            return formatTime(session.stepTimeRemaining ?? 0)
        } else {
            return formatTime(session.stepElapsedTime)
        }
    }

    var timeLabel: String {
        isTimed ? "Remaining" : "Elapsed"
    }

    var progressFraction: Double { session.progress }

    var stepLabel: String {
        "Step \(session.currentStepIndex + 1) of \(session.totalSteps)"
    }

    var currentBeat: Int { metronome.currentBeat }
    var currentMeasure: Int { metronome.currentMeasure }

    var beatsPerMeasure: Int {
        session.currentStep.metronome?.timeSignature.beatsPerMeasure ?? 4
    }

    /// The effective BPM for the current step, accounting for any override.
    var currentBPM: Int {
        effectiveBPM(for: session.currentStepIndex)
    }

    /// The original BPM from the routine definition for the current step.
    var originalBPM: Int? {
        session.currentStep.metronome?.bpm
    }

    /// Whether the current step's BPM has been modified from the original.
    var currentStepBPMModified: Bool {
        bpmOverrides[session.currentStepIndex] != nil
    }

    var currentTimeSignature: TimeSignature? {
        session.currentStep.metronome?.timeSignature
    }

    // MARK: - Init

    init(routine: PracticeRoutine) {
        self.session = PracticeSession(routine: routine)
        self.metronome = MetronomeEngine()
        self.soundPlayer = SoundPlayer()
        self.speechRecognizer = SpeechRecognizer()

        speechRecognizer.onCommand = { [weak self] command in
            self?.handleVoiceCommand(command)
        }
    }

    // MARK: - BPM Adjustment

    func adjustBPM(by delta: Int) {
        guard let config = session.currentStep.metronome else { return }
        let current = effectiveBPM(for: session.currentStepIndex)
        let newBPM = min(300, max(20, current + delta))
        guard newBPM != current else { return }

        // Store the override
        if newBPM == config.bpm {
            // Reset to original — remove the override
            bpmOverrides.removeValue(forKey: session.currentStepIndex)
        } else {
            bpmOverrides[session.currentStepIndex] = newBPM
        }

        // Apply immediately to running metronome
        let newConfig = config.withBPM(newBPM)
        metronome.updateConfig(newConfig)
        if session.state == .playing {
            metronome.start()
        }
    }

    func resetBPM() {
        guard let config = session.currentStep.metronome else { return }
        bpmOverrides.removeValue(forKey: session.currentStepIndex)

        metronome.updateConfig(config)
        if session.state == .playing {
            metronome.start()
        }
    }

    /// Build a modified routine with all BPM overrides applied.
    func routineWithBPMChanges() -> PracticeRoutine {
        let modifiedSteps = session.routine.steps.enumerated().map { index, step in
            if let overrideBPM = bpmOverrides[index], let config = step.metronome {
                return step.withMetronome(config.withBPM(overrideBPM))
            }
            return step
        }
        return session.routine.withSteps(modifiedSteps)
    }

    /// Summary of which steps had BPM changes.
    var bpmChangeSummary: [String] {
        bpmOverrides.sorted(by: { $0.key < $1.key }).compactMap { index, newBPM in
            let step = session.routine.steps[index]
            guard let original = step.metronome?.bpm else { return nil }
            return "\(step.name): \(original) → \(newBPM) BPM"
        }
    }

    // MARK: - Voice Commands

    func toggleVoice() {
        if speechRecognizer.isListening {
            speechRecognizer.stopListening()
        } else {
            speechRecognizer.requestPermissionAndStart()
        }
    }

    private func handleVoiceCommand(_ command: VoiceCommand) {
        lastVoiceCommand = command
        lastVoiceCommandTime = Date()

        switch command {
        case .start:
            if session.state == .ready || session.state == .paused || session.state == .stepComplete {
                togglePlayPause()
            }
        case .pause:
            if session.state == .playing {
                togglePlayPause()
            }
        case .next:
            nextStep()
        case .faster:
            adjustBPM(by: 5)
        case .slower:
            adjustBPM(by: -5)
        }
    }

    // MARK: - Actions

    func start() {
        speechRecognizer.requestPermissionAndStart()
        startCurrentStep()
    }

    func togglePlayPause() {
        switch session.state {
        case .ready:
            startCurrentStep()
        case .playing:
            pause()
        case .paused:
            resume()
        case .stepComplete:
            nextStep()
        case .completed:
            break
        }
    }

    func nextStep() {
        stopTimerAndMetronome()

        if session.isLastStep {
            session.state = .completed
            soundPlayer.playSessionEnd()
        } else {
            session.currentStepIndex += 1
            session.stepElapsedTime = 0
            startCurrentStep()
        }
    }

    func previousStep() {
        guard !session.isFirstStep else { return }
        stopTimerAndMetronome()
        session.currentStepIndex -= 1
        session.stepElapsedTime = 0
        startCurrentStep()
    }

    func skipStep() {
        nextStep()
    }

    func goToStep(_ index: Int) {
        guard index >= 0, index < session.totalSteps, index != session.currentStepIndex else { return }
        stopTimerAndMetronome()
        session.currentStepIndex = index
        session.stepElapsedTime = 0
        startCurrentStep()
    }

    func cleanup() {
        stopTimerAndMetronome()
        speechRecognizer.stopListening()
    }

    // MARK: - Private

    private func effectiveBPM(for stepIndex: Int) -> Int {
        if let override = bpmOverrides[stepIndex] {
            return override
        }
        return session.routine.steps[stepIndex].metronome?.bpm ?? 0
    }

    private func effectiveConfig(for stepIndex: Int) -> MetronomeConfig? {
        guard let config = session.routine.steps[stepIndex].metronome else { return nil }
        if let override = bpmOverrides[stepIndex] {
            return config.withBPM(override)
        }
        return config
    }

    private func startCurrentStep() {
        session.state = .playing
        session.stepElapsedTime = 0
        startTimer()

        if let config = effectiveConfig(for: session.currentStepIndex) {
            metronome.updateConfig(config)
            metronome.start()
        }
    }

    private func pause() {
        session.state = .paused
        stopTimer()
        metronome.stop()
    }

    private func resume() {
        session.state = .playing
        startTimer()

        if session.currentStep.hasMetronome {
            metronome.start()
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.session.stepElapsedTime += 0.1
            self.session.sessionElapsedTime += 0.1

            if let remaining = self.session.stepTimeRemaining, remaining <= 0 {
                self.onTimedStepComplete()
            }
        }
    }

    private func onTimedStepComplete() {
        stopTimer()
        metronome.stop()
        session.state = .stepComplete
        soundPlayer.playStepCompletion()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func stopTimerAndMetronome() {
        stopTimer()
        metronome.stop()
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(max(0, seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
