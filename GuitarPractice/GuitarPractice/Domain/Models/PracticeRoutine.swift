import Foundation

// MARK: - RoutineCategory

enum RoutineCategory: String, Codable, CaseIterable, Identifiable {
    case warmup
    case chords
    case scales
    case fingerpicking
    case strumming
    case theory
    case songs
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warmup: "Warmup"
        case .chords: "Chords"
        case .scales: "Scales"
        case .fingerpicking: "Fingerpicking"
        case .strumming: "Strumming"
        case .theory: "Theory"
        case .songs: "Songs"
        case .custom: "Custom"
        }
    }
}

// MARK: - TimeSignature

struct TimeSignature: Codable, Hashable {
    let beatsPerMeasure: Int
    let beatUnit: Int

    static let fourFour = TimeSignature(beatsPerMeasure: 4, beatUnit: 4)
    static let threeFour = TimeSignature(beatsPerMeasure: 3, beatUnit: 4)
    static let sixEight = TimeSignature(beatsPerMeasure: 6, beatUnit: 8)
}

// MARK: - MetronomeConfig

struct MetronomeConfig: Codable, Hashable {
    let bpm: Int
    let timeSignature: TimeSignature
    let accentDownbeat: Bool
    let subdivisions: Int
    let swing: Double

    init(bpm: Int, timeSignature: TimeSignature = .fourFour,
         accentDownbeat: Bool = true, subdivisions: Int = 1, swing: Double = 0.5) {
        self.bpm = min(300, max(20, bpm))
        self.timeSignature = timeSignature
        self.accentDownbeat = accentDownbeat
        self.subdivisions = max(1, subdivisions)
        self.swing = min(0.75, max(0.5, swing))
    }

    func withBPM(_ newBPM: Int) -> MetronomeConfig {
        MetronomeConfig(bpm: newBPM, timeSignature: timeSignature,
                        accentDownbeat: accentDownbeat, subdivisions: subdivisions, swing: swing)
    }

    func withSwing(_ newSwing: Double) -> MetronomeConfig {
        MetronomeConfig(bpm: bpm, timeSignature: timeSignature,
                        accentDownbeat: accentDownbeat, subdivisions: subdivisions, swing: newSwing)
    }
}

extension MetronomeConfig {
    enum CodingKeys: String, CodingKey {
        case bpm, timeSignature, accentDownbeat, subdivisions, swing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawBpm = try container.decode(Int.self, forKey: .bpm)
        let timeSignature = try container.decodeIfPresent(TimeSignature.self, forKey: .timeSignature) ?? .fourFour
        let accentDownbeat = try container.decodeIfPresent(Bool.self, forKey: .accentDownbeat) ?? true
        let subdivisions = try container.decodeIfPresent(Int.self, forKey: .subdivisions) ?? 1
        let swing = try container.decodeIfPresent(Double.self, forKey: .swing) ?? 0.5
        self.init(bpm: rawBpm, timeSignature: timeSignature, accentDownbeat: accentDownbeat, subdivisions: subdivisions, swing: swing)
    }
}

// MARK: - PracticeStep

struct PracticeStep: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let instructions: String
    let duration: TimeInterval?
    let metronome: MetronomeConfig?
    let notes: String?
    let images: [String]?
    let chords: [String]?
    let measuresPerChord: Int?

    init(id: UUID = UUID(), name: String, instructions: String,
         duration: TimeInterval?, metronome: MetronomeConfig?, notes: String?,
         images: [String]? = nil, chords: [String]? = nil, measuresPerChord: Int? = nil) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.duration = duration
        self.metronome = metronome
        self.notes = notes
        self.images = images
        self.chords = chords
        self.measuresPerChord = measuresPerChord
    }

    var isTimed: Bool { duration != nil }
    var hasMetronome: Bool { metronome != nil }
    var hasChords: Bool { !(chords?.isEmpty ?? true) }
    var hasImages: Bool { !(images?.isEmpty ?? true) }

    func withMetronome(_ newConfig: MetronomeConfig?) -> PracticeStep {
        PracticeStep(id: id, name: name, instructions: instructions,
                     duration: duration, metronome: newConfig, notes: notes,
                     images: images, chords: chords, measuresPerChord: measuresPerChord)
    }
}

extension PracticeStep {
    enum CodingKeys: String, CodingKey {
        case id, name, instructions, duration, metronome, notes
        case images, chords, measuresPerChord
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.instructions = try container.decode(String.self, forKey: .instructions)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.metronome = try container.decodeIfPresent(MetronomeConfig.self, forKey: .metronome)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.images = try container.decodeIfPresent([String].self, forKey: .images)
        self.chords = try container.decodeIfPresent([String].self, forKey: .chords)
        self.measuresPerChord = try container.decodeIfPresent(Int.self, forKey: .measuresPerChord)
    }
}

// MARK: - PracticeRoutine

struct PracticeRoutine: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let category: RoutineCategory
    let estimatedDurationMinutes: Int?
    let tags: [String]
    let steps: [PracticeStep]

    init(id: UUID = UUID(), name: String, description: String, category: RoutineCategory,
         estimatedDurationMinutes: Int?, tags: [String], steps: [PracticeStep]) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.tags = tags
        self.steps = steps
    }

    var totalTimedDuration: TimeInterval {
        steps.compactMap(\.duration).reduce(0, +)
    }

    var stepCount: Int { steps.count }

    var timedStepCount: Int {
        steps.filter(\.isTimed).count
    }

    var untimedStepCount: Int {
        steps.filter { !$0.isTimed }.count
    }

    func withSteps(_ newSteps: [PracticeStep]) -> PracticeRoutine {
        PracticeRoutine(id: id, name: name, description: description,
                        category: category, estimatedDurationMinutes: estimatedDurationMinutes,
                        tags: tags, steps: newSteps)
    }
}

extension PracticeRoutine {
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, estimatedDurationMinutes, tags, steps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.category = try container.decode(RoutineCategory.self, forKey: .category)
        self.estimatedDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedDurationMinutes)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.steps = try container.decode([PracticeStep].self, forKey: .steps)
    }
}
