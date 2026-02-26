import AVFoundation
import Foundation
import Observation

@Observable
class TunerEngine {
    // MARK: - Public State

    private(set) var isActive: Bool = false
    private(set) var detectedFrequency: Double?
    private(set) var detectedNote: String?
    private(set) var detectedOctave: Int?
    private(set) var centsOffset: Double = 0

    // MARK: - Private

    private let engine = AVAudioEngine()
    private var sampleRate: Double = 44100.0
    private let bufferSize: AVAudioFrameCount = 2048
    private let yinThreshold: Double = 0.15

    // Note names for display
    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // MARK: - Public API

    func start() {
        guard !isActive else { return }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        sampleRate = format.sampleRate > 0 ? format.sampleRate : 44100.0

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        do {
            try engine.start()
            isActive = true
        } catch {
            print("TunerEngine: failed to start: \(error)")
        }
    }

    func stop() {
        guard isActive else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isActive = false

        DispatchQueue.main.async { [weak self] in
            self?.detectedFrequency = nil
            self?.detectedNote = nil
            self?.detectedOctave = nil
            self?.centsOffset = 0
        }
    }

    // MARK: - Audio Processing

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // Check if signal is loud enough (RMS threshold)
        var rms: Float = 0
        for i in 0..<frameCount {
            rms += channelData[i] * channelData[i]
        }
        rms = sqrtf(rms / Float(frameCount))

        guard rms > 0.01 else {
            DispatchQueue.main.async { [weak self] in
                self?.detectedFrequency = nil
                self?.detectedNote = nil
                self?.detectedOctave = nil
                self?.centsOffset = 0
            }
            return
        }

        // Run YIN pitch detection
        guard let frequency = yinPitchDetect(channelData, frameCount: frameCount) else {
            DispatchQueue.main.async { [weak self] in
                self?.detectedFrequency = nil
                self?.detectedNote = nil
                self?.detectedOctave = nil
                self?.centsOffset = 0
            }
            return
        }

        // Convert frequency to note
        let (note, octave, cents) = frequencyToNote(frequency)

        DispatchQueue.main.async { [weak self] in
            self?.detectedFrequency = frequency
            self?.detectedNote = note
            self?.detectedOctave = octave
            self?.centsOffset = cents
        }
    }

    // MARK: - YIN Algorithm

    private func yinPitchDetect(_ data: UnsafePointer<Float>, frameCount: Int) -> Double? {
        let halfCount = frameCount / 2

        // Step 1 & 2: Difference function + cumulative mean normalized difference
        var yinBuffer = [Double](repeating: 0, count: halfCount)
        yinBuffer[0] = 1.0

        var runningSum: Double = 0

        for tau in 1..<halfCount {
            var diff: Double = 0
            for i in 0..<halfCount {
                let delta = Double(data[i]) - Double(data[i + tau])
                diff += delta * delta
            }
            yinBuffer[tau] = diff
            runningSum += diff

            // Cumulative mean normalization
            if runningSum > 0 {
                yinBuffer[tau] = yinBuffer[tau] * Double(tau) / runningSum
            } else {
                yinBuffer[tau] = 1.0
            }
        }

        // Step 3: Absolute threshold — find first dip below threshold
        var tauEstimate = -1
        for tau in 2..<halfCount {
            if yinBuffer[tau] < yinThreshold {
                // Find the local minimum
                while tau + 1 < halfCount && yinBuffer[tau + 1] < yinBuffer[tau] {
                    tauEstimate = tau + 1
                    break
                }
                if tauEstimate < 0 { tauEstimate = tau }
                break
            }
        }

        guard tauEstimate > 0 else { return nil }

        // Step 4: Parabolic interpolation for sub-sample accuracy
        let betterTau: Double
        if tauEstimate > 0 && tauEstimate < halfCount - 1 {
            let s0 = yinBuffer[tauEstimate - 1]
            let s1 = yinBuffer[tauEstimate]
            let s2 = yinBuffer[tauEstimate + 1]
            let adjustment = (s2 - s0) / (2.0 * (2.0 * s1 - s2 - s0))
            betterTau = Double(tauEstimate) + adjustment
        } else {
            betterTau = Double(tauEstimate)
        }

        let frequency = sampleRate / betterTau

        // Filter: guitar range is roughly 60 Hz to 1400 Hz
        guard frequency > 60 && frequency < 1400 else { return nil }

        return frequency
    }

    // MARK: - Frequency to Note Conversion

    private func frequencyToNote(_ frequency: Double) -> (note: String, octave: Int, cents: Double) {
        // MIDI note number: A4 = 440 Hz = MIDI 69
        let midiNote = 12.0 * log2(frequency / 440.0) + 69.0
        let roundedMidi = Int(midiNote.rounded())
        let cents = (midiNote - Double(roundedMidi)) * 100.0

        let noteIndex = ((roundedMidi % 12) + 12) % 12
        let octave = (roundedMidi / 12) - 1

        return (Self.noteNames[noteIndex], octave, cents)
    }
}
