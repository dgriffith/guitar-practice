import AVFoundation
import Foundation

/// Plays one-shot notification sounds for step completion and session end.
/// Uses a dedicated AVAudioEngine + AVAudioPlayerNode so it doesn't interfere
/// with the metronome's audio engine.
class SoundPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private var completionBuffer: AVAudioPCMBuffer?
    private var sessionEndBuffer: AVAudioPCMBuffer?

    init() {
        setupAudioGraph()
        generateBuffers()
    }

    deinit {
        engine.stop()
    }

    func playStepCompletion() {
        guard let buffer = completionBuffer else { return }
        play(buffer: buffer)
    }

    func playSessionEnd() {
        guard let buffer = sessionEndBuffer else { return }
        play(buffer: buffer)
    }

    // MARK: - Private

    private func setupAudioGraph() {
        engine.attach(playerNode)
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        engine.connect(playerNode, to: mainMixer, format: format)
        engine.prepare()
    }

    private func generateBuffers() {
        let sampleRate = Float(engine.mainMixerNode.outputFormat(forBus: 0).sampleRate)
        let sr = sampleRate > 0 ? sampleRate : 44100.0
        completionBuffer = ClickSoundGenerator.completionChime(sampleRate: sr)
        sessionEndBuffer = ClickSoundGenerator.sessionEndChime(sampleRate: sr)
    }

    private func play(buffer: AVAudioPCMBuffer) {
        do {
            if !engine.isRunning {
                try engine.start()
            }
            playerNode.stop()
            playerNode.play()
            playerNode.scheduleBuffer(buffer, at: nil, options: [])
        } catch {
            print("SoundPlayer failed to play: \(error)")
        }
    }
}
