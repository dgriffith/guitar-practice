import AVFoundation
import Foundation
import Observation
import Speech

// MARK: - VoiceCommand

enum VoiceCommand: String, CaseIterable {
    case restart
    case start
    case pause
    case next
    case back
    case faster
    case slower

    /// All words that should trigger this command.
    var triggerWords: [String] {
        switch self {
        case .start: ["start", "go", "play", "resume"]
        case .pause: ["pause", "stop", "wait"]
        case .next: ["next", "skip"]
        case .back: ["back", "previous"]
        case .restart: ["restart", "again", "repeat"]
        case .faster: ["faster", "fast", "speed up", "quicker"]
        case .slower: ["slower", "slow", "slow down"]
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - SpeechRecognizer

/// Uses AVCaptureSession for audio input (instead of AVAudioEngine) to avoid
/// conflicts with the MetronomeEngine which has its own AVAudioEngine.
@Observable
class SpeechRecognizer: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, SFSpeechRecognizerDelegate {
    private(set) var isListening: Bool = false
    private(set) var isAvailable: Bool = false
    private(set) var lastCommand: VoiceCommand?
    private(set) var lastCommandTime: Date?

    var onCommand: ((VoiceCommand) -> Void)?

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var captureSession: AVCaptureSession?
    private let captureQueue = DispatchQueue(label: "com.guitarpractice.speechCapture")

    private var lastProcessedIndex: Int = 0
    private var lastCommandFireTime: Date = .distantPast
    private let debounceInterval: TimeInterval = 1.5
    private var shouldRestart: Bool = false

    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        isAvailable = speechRecognizer?.isAvailable ?? false
        super.init()
        speechRecognizer?.delegate = self
    }

    // MARK: - SFSpeechRecognizerDelegate

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isAvailable = available
            if available && self.shouldRestart && !self.isListening {
                self.beginRecognitionSession()
            }
        }
    }

    // MARK: - Public API

    func requestPermissionAndStart() {
        // Request both speech recognition AND microphone permissions
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }
                guard status == .authorized else {
                    self.isAvailable = false
                    return
                }
                self.isAvailable = true
                // Now ensure microphone access for AVCaptureSession
                let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                if micStatus == .authorized {
                    self.startListening()
                } else if micStatus == .notDetermined {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        DispatchQueue.main.async {
                            if granted { self.startListening() }
                        }
                    }
                }
            }
        }
    }

    func startListening() {
        guard !isListening else { return }
        shouldRestart = true

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            // Not available yet — the delegate callback will start us when it becomes available
            return
        }

        beginRecognitionSession()
    }

    func stopListening() {
        shouldRestart = false
        tearDownRecognition()
        isListening = false
    }

    // MARK: - AVCaptureAudioDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        recognitionRequest?.appendAudioSampleBuffer(sampleBuffer)
    }

    // MARK: - Private

    private func beginRecognitionSession() {
        tearDownRecognition()

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            scheduleRetry()
            return
        }

        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            scheduleRetry()
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        self.recognitionRequest = request
        self.lastProcessedIndex = 0

        // Set up AVCaptureSession for microphone input
        let session = AVCaptureSession()
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            scheduleRetry()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: microphone)
            guard session.canAddInput(input) else {
                scheduleRetry()
                return
            }
            session.addInput(input)
        } catch {
            scheduleRetry()
            return
        }

        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: captureQueue)
        guard session.canAddOutput(audioOutput) else {
            scheduleRetry()
            return
        }
        session.addOutput(audioOutput)

        self.captureSession = session
        session.startRunning()

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                self.processResult(result)
            }

            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self, self.shouldRestart else { return }
                    self.beginRecognitionSession()
                }
            }
        }

        isListening = true
    }

    private func scheduleRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self, self.shouldRestart, !self.isListening else { return }
            self.beginRecognitionSession()
        }
    }

    private func processResult(_ result: SFSpeechRecognitionResult) {
        let transcript = result.bestTranscription.formattedString.lowercased()
        let words = transcript.split(separator: " ").map(String.init)

        guard words.count > lastProcessedIndex else { return }
        let newWords = Array(words[lastProcessedIndex...])
        lastProcessedIndex = words.count

        let newText = newWords.joined(separator: " ")
        for command in VoiceCommand.allCases {
            for trigger in command.triggerWords {
                if newText.contains(trigger) {
                    fireCommand(command)
                    return
                }
            }
        }
    }

    private func fireCommand(_ command: VoiceCommand) {
        let now = Date()
        if command == lastCommand, now.timeIntervalSince(lastCommandFireTime) < debounceInterval {
            return
        }

        lastCommandFireTime = now

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lastCommand = command
            self.lastCommandTime = now
            self.onCommand?(command)
        }
    }

    private func tearDownRecognition() {
        captureSession?.stopRunning()
        captureSession = nil
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}
