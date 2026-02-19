import AVFoundation
import Foundation

@Observable
class MetronomeEngine {
    // MARK: - Public State

    private(set) var isPlaying: Bool = false
    private(set) var currentBeat: Int = 0
    private(set) var currentMeasure: Int = 1
    private(set) var isInDropout: Bool = false

    // MARK: - Configuration

    private(set) var config: MetronomeConfig

    // MARK: - Dropout Configuration

    var dropoutEnabled: Bool = false
    var dropoutPlayMeasures: Int = 4
    var dropoutMuteMeasures: Int = 2
    private var measuresInPhase: Int = 0

    // MARK: - Audio Graph

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var bufferSampleRate: Double = 44100.0
    private var audioFormat: AVAudioFormat!

    // MARK: - Click source buffers (short click sounds)

    private var downbeatClick: AVAudioPCMBuffer!
    private var normalClick: AVAudioPCMBuffer!
    private var subdivisionClick: AVAudioPCMBuffer!

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
        isInDropout = false
        measuresInPhase = 0

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
        isInDropout = false
        measuresInPhase = 0
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

    func setDropout(enabled: Bool, play: Int, mute: Int) {
        dropoutEnabled = enabled
        dropoutPlayMeasures = max(1, play)
        dropoutMuteMeasures = max(1, mute)
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
        subdivisionClick = ClickSoundGenerator.subdivisionClick(sampleRate: sr)
    }

    // MARK: - Beat Scheduling

    private enum BeatType { case downbeat, normal, subdivision }

    /// Compute the duration in seconds for a specific sub-beat, accounting for swing.
    private func subBeatDuration(beatInMeasure: Int) -> Double {
        let baseBeatDuration = 60.0 / Double(config.bpm)

        if config.subdivisions == 2 && config.swing != 0.5 {
            // Swing: on-beat sub-beats are longer, off-beat sub-beats are shorter
            let isOnBeat = beatInMeasure % 2 == 0
            return isOnBeat
                ? baseBeatDuration * config.swing
                : baseBeatDuration * (1.0 - config.swing)
        }

        // Straight timing
        return baseBeatDuration / Double(config.subdivisions)
    }

    /// Creates a buffer that is exactly one sub-beat long: click sound followed by silence.
    private func makeBeatBuffer(type: BeatType, durationSeconds: Double, silent: Bool) -> AVAudioPCMBuffer {
        let totalFrames = AVAudioFrameCount(durationSeconds * bufferSampleRate)

        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: totalFrames)!
        buffer.frameLength = totalFrames

        guard !silent else { return buffer } // all zeros = silence

        let click: AVAudioPCMBuffer = switch type {
        case .downbeat: config.accentDownbeat ? downbeatClick : normalClick
        case .normal: normalClick
        case .subdivision: subdivisionClick
        }
        let clickFrames = min(click.frameLength, totalFrames)

        let outL = buffer.floatChannelData![0]
        let outR = buffer.floatChannelData![1]
        let srcL = click.floatChannelData![0]
        let srcR = click.floatChannelData![1]

        for i in 0..<Int(clickFrames) {
            outL[i] = srcL[i]
            outR[i] = srcR[i]
        }

        return buffer
    }

    /// Schedule one beat, then chain to the next via completion handler.
    private func scheduleBeat(beatInMeasure: Int, measure: Int, generation gen: Int) {
        guard isPlaying, gen == generation else { return }

        // Dropout phase tracking at the start of each measure
        if beatInMeasure == 0 && dropoutEnabled {
            measuresInPhase += 1
            if isInDropout {
                if measuresInPhase > dropoutMuteMeasures {
                    measuresInPhase = 1
                    isInDropout = false
                }
            } else {
                if measuresInPhase > dropoutPlayMeasures {
                    measuresInPhase = 1
                    isInDropout = true
                }
            }
        }

        let isMainBeat = config.subdivisions <= 1 || beatInMeasure % config.subdivisions == 0
        let beatType: BeatType = beatInMeasure == 0 ? .downbeat : (isMainBeat ? .normal : .subdivision)
        let duration = subBeatDuration(beatInMeasure: beatInMeasure)
        let buffer = makeBeatBuffer(type: beatType, durationSeconds: duration, silent: isInDropout)

        let displayBeat = beatInMeasure + 1
        let displayMeasure = measure
        let dropoutState = isInDropout

        // Update UI immediately when the beat is scheduled to play
        DispatchQueue.main.async { [weak self] in
            guard let self, self.generation == gen else { return }
            self.currentBeat = displayBeat
            self.currentMeasure = displayMeasure
            self.isInDropout = dropoutState
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
