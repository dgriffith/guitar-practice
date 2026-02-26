import Foundation

struct ChordFingering {
    /// Fret for each string, low E (6th) to high E (1st).
    /// -1 = muted/not played, 0 = open, 1+ = fret number.
    let frets: [Int]
    /// Starting fret for the diagram (1 for open position chords).
    let baseFret: Int
    /// Fret numbers (relative to baseFret) that have a barre.
    let barres: [Int]

    init(frets: [Int], baseFret: Int = 1, barres: [Int] = []) {
        self.frets = frets
        self.baseFret = baseFret
        self.barres = barres
    }
}

enum ChordLibrary {
    /// Look up a chord fingering by name. Returns nil for unknown chords.
    static func fingering(for name: String) -> ChordFingering? {
        chords[name]
    }

    static let chords: [String: ChordFingering] = [
        // Open major chords
        "A":     ChordFingering(frets: [-1, 0, 2, 2, 2, 0]),
        "C":     ChordFingering(frets: [-1, 3, 2, 0, 1, 0]),
        "D":     ChordFingering(frets: [-1, -1, 0, 2, 3, 2]),
        "E":     ChordFingering(frets: [0, 2, 2, 1, 0, 0]),
        "G":     ChordFingering(frets: [3, 2, 0, 0, 0, 3]),

        // Open minor chords
        "Am":    ChordFingering(frets: [-1, 0, 2, 2, 1, 0]),
        "Dm":    ChordFingering(frets: [-1, -1, 0, 2, 3, 1]),
        "Em":    ChordFingering(frets: [0, 2, 2, 0, 0, 0]),

        // Sus2 chords
        "Asus2": ChordFingering(frets: [-1, 0, 2, 2, 0, 0]),
        "Dsus2": ChordFingering(frets: [-1, -1, 0, 2, 3, 0]),

        // Sus4 chords
        "Asus4": ChordFingering(frets: [-1, 0, 2, 2, 3, 0]),
        "Dsus4": ChordFingering(frets: [-1, -1, 0, 2, 3, 3]),
        "Esus4": ChordFingering(frets: [0, 2, 2, 2, 0, 0]),

        // Dominant 7th chords
        "A7":    ChordFingering(frets: [-1, 0, 2, 0, 2, 0]),
        "B7":    ChordFingering(frets: [-1, 2, 1, 2, 0, 2]),
        "D7":    ChordFingering(frets: [-1, -1, 0, 2, 1, 2]),
        "E7":    ChordFingering(frets: [0, 2, 0, 1, 0, 0]),
        "G7":    ChordFingering(frets: [3, 2, 0, 0, 0, 1]),

        // Minor 7th chords
        "Am7":   ChordFingering(frets: [-1, 0, 2, 0, 1, 0]),

        // Major 7th chords
        "Amaj7": ChordFingering(frets: [-1, 0, 2, 1, 2, 0]),
        "Cmaj7": ChordFingering(frets: [-1, 3, 2, 0, 0, 0]),
        "Dmaj7": ChordFingering(frets: [-1, -1, 0, 2, 2, 2]),
        "Emaj7": ChordFingering(frets: [0, 2, 1, 1, 0, 0]),
        "Gmaj7": ChordFingering(frets: [3, 2, 0, 0, 0, 2]),

        // Add chords
        "Cadd9": ChordFingering(frets: [-1, 3, 2, 0, 3, 0]),

        // Barre chords
        "F":     ChordFingering(frets: [1, 1, 2, 3, 3, 1], baseFret: 1, barres: [1]),

        // Slash chords
        "G/B":   ChordFingering(frets: [-1, 2, 0, 0, 0, 3]),
    ]
}
