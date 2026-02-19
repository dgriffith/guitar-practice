import AVFoundation
import Foundation

@Observable
class MetronomeEngine {
    // MARK: - Public State

    private(set) var isPlaying: Bool = false
    private(set) var currentBeat: Int = 0
    private(set) var currentMeasure: Int = 1

    // MARK: - Configuration

    private(set) var config: MetronomeConfig

    // MARK: - Audio Graph

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var bufferSampleRate: Double = 44100.0
    private var audioFormat: AVAudioFormat!

    // MARK: - Click source buffers (short click sounds)

    private var downbeatClick: AVAudioPCMBuffer!
    private var normalClick: AVAudioPCMBuffer!

    // MARK: - Generation tracking to invalidate stale callbacks

    private var generation: Int = 0

    // MARK: - Init

    init(config: MetronomeConfig = MetronomeConfig(bpm: 120)) {
        self.config = config
        setupAudioGraph()
        regenerateClicks()
    }

    deinit {
        stop()
        engine.stop()
    }

    // MARK: - Public API

    func start() {
        stop()

        generation += 1
        let currentGen = generation

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("MetronomeEngine: failed to start AVAudioEngine: \(error)")
                return
            }
        }

        isPlaying = true
        currentBeat = 0
        currentMeasure = 1

        playerNode.play()

        // Kick off the beat chain
        scheduleBeat(beatInMeasure: 0, measure: 1, generation: currentGen)
    }

    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        generation += 1 // invalidate any pending completion handlers
        playerNode.stop()
        currentBeat = 0
        currentMeasure = 1
    }

    func updateConfig(_ newConfig: MetronomeConfig) {
        let wasPlaying = isPlaying
        stop()
        config = newConfig
        regenerateClicks()
        if wasPlaying {
            start()
        }
    }

    // MARK: - Private Setup

    private func setupAudioGraph() {
        engine.attach(playerNode)
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        bufferSampleRate = format.sampleRate > 0 ? format.sampleRate : 44100.0
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: bufferSampleRate, channels: 2)!
        engine.connect(playerNode, to: mainMixer, format: audioFormat)
        engine.prepare()
    }

    private func regenerateClicks() {
        let sr = Float(bufferSampleRate)
        downbeatClick = ClickSoundGenerator.downbeatClick(sampleRate: sr)
        normalClick = ClickSoundGenerator.normalClick(sampleRate: sr)
    }

    // MARK: - Beat Scheduling

    /// Creates a buffer that is exactly one beat long: click sound followed by silence.
    /// The buffer duration *is* the beat timing — no external clock needed.
    private func makeBeatBuffer(isDownbeat: Bool) -> AVAudioPCMBuffer {
        let effectiveBPM = Double(config.bpm * config.subdivisions)
        let beatDurationSec = 60.0 / effectiveBPM
        let totalFrames = AVAudioFrameCount(beatDurationSec * bufferSampleRate)

        let click = (isDownbeat && config.accentDownbeat) ? downbeatClick! : normalClick!
        let clickFrames = min(click.frameLength, totalFrames)

        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: totalFrames)!
        buffer.frameLength = totalFrames

        let outL = buffer.floatChannelData![0]
        let outR = buffer.floatChannelData![1]
        let srcL = click.floatChannelData![0]
        let srcR = click.floatChannelData![1]

        // Copy click samples
        for i in 0..<Int(clickFrames) {
            outL[i] = srcL[i]
            outR[i] = srcR[i]
        }
        // Remaining frames are already zeroed by AVAudioPCMBuffer

        return buffer
    }

    /// Schedule one beat, then chain to the next via completion handler.
    private func scheduleBeat(beatInMeasure: Int, measure: Int, generation gen: Int) {
        guard isPlaying, gen == generation else { return }

        let isDown = beatInMeasure == 0
        let buffer = makeBeatBuffer(isDownbeat: isDown)

        let displayBeat = beatInMeasure + 1
        let displayMeasure = measure

        // Update UI immediately when the beat is scheduled to play
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generation == gen else { return }
            self.currentBeat = displayBeat
            self.currentMeasure = displayMeasure
        }

        let totalSubBeats = config.timeSignature.beatsPerMeasure * config.subdivisions
        var nextBeatInMeasure = beatInMeasure + 1
        var nextMeasure = measure
        if nextBeatInMeasure >= totalSubBeats {
            nextBeatInMeasure = 0
            nextMeasure += 1
        }

        playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
            guard let self, self.generation == gen else { return }
            self.scheduleBeat(beatInMeasure: nextBeatInMeasure, measure: nextMeasure, generation: gen)
        }
    }
}
