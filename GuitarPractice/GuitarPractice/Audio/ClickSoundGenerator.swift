import AVFoundation

struct ClickSoundGenerator {
    /// Generate a click buffer with an attack-decay envelope.
    /// - Parameters:
    ///   - frequency: Pitch in Hz (880 for downbeat, 440 for normal beat)
    ///   - durationSeconds: Total click duration
    ///   - sampleRate: Audio sample rate
    ///   - amplitude: Peak amplitude (0.0...1.0)
    static func generateClick(
        frequency: Float = 880.0,
        durationSeconds: Float = 0.02,
        sampleRate: Float = 44100.0,
        amplitude: Float = 0.8
    ) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        let frameCount = AVAudioFrameCount(durationSeconds * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]

        for i in 0..<Int(frameCount) {
            let time = Float(i) / sampleRate
            let envelope = amplitude * exp(-time * 200.0)
            let sample = envelope * sin(2.0 * .pi * frequency * time)
            leftChannel[i] = sample
            rightChannel[i] = sample
        }

        return buffer
    }

    /// Higher-pitched click for the downbeat (beat 1)
    static func downbeatClick(sampleRate: Float = 44100.0) -> AVAudioPCMBuffer {
        generateClick(frequency: 880.0, durationSeconds: 0.025, sampleRate: sampleRate, amplitude: 0.9)
    }

    /// Standard click for non-accented beats
    static func normalClick(sampleRate: Float = 44100.0) -> AVAudioPCMBuffer {
        generateClick(frequency: 440.0, durationSeconds: 0.02, sampleRate: sampleRate, amplitude: 0.7)
    }

    /// Generate a short chime sound for step completion notifications
    static func completionChime(sampleRate: Float = 44100.0) -> AVAudioPCMBuffer {
        let durationSeconds: Float = 0.5
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        let frameCount = AVAudioFrameCount(durationSeconds * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]

        // Two-tone ascending chime: C5 (523Hz) then E5 (659Hz)
        let freq1: Float = 523.25
        let freq2: Float = 659.25
        let halfPoint = Int(frameCount) / 2

        for i in 0..<Int(frameCount) {
            let time = Float(i) / sampleRate
            let freq = i < halfPoint ? freq1 : freq2
            let localTime = i < halfPoint ? time : Float(i - halfPoint) / sampleRate
            let envelope: Float = 0.6 * exp(-localTime * 8.0)
            let sample = envelope * sin(2.0 * .pi * freq * time)
            leftChannel[i] = sample
            rightChannel[i] = sample
        }

        return buffer
    }

    /// Generate a longer chord sound for session completion
    static func sessionEndChime(sampleRate: Float = 44100.0) -> AVAudioPCMBuffer {
        let durationSeconds: Float = 1.0
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        let frameCount = AVAudioFrameCount(durationSeconds * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let leftChannel = buffer.floatChannelData![0]
        let rightChannel = buffer.floatChannelData![1]

        // C major triad: C4, E4, G4
        let frequencies: [Float] = [261.63, 329.63, 392.00]

        for i in 0..<Int(frameCount) {
            let time = Float(i) / sampleRate
            let envelope: Float = 0.4 * exp(-time * 3.0)
            var sample: Float = 0
            for freq in frequencies {
                sample += envelope * sin(2.0 * .pi * freq * time)
            }
            sample /= Float(frequencies.count)
            leftChannel[i] = sample
            rightChannel[i] = sample
        }

        return buffer
    }
}
