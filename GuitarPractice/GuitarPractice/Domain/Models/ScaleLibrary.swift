import Foundation

struct ScalePosition {
    /// Fret numbers for scale tones on each string, low E (6th) to high E (1st).
    let frets: [[Int]]
    /// Fret numbers for root notes on each string (subset of frets).
    let roots: [[Int]]
    /// First fret shown. 0 = open position with nut.
    let startFret: Int
    /// Number of frets to display (default 4).
    let fretCount: Int

    init(frets: [[Int]], roots: [[Int]], startFret: Int, fretCount: Int = 4) {
        self.frets = frets
        self.roots = roots
        self.startFret = startFret
        self.fretCount = fretCount
    }
}

enum ScaleLibrary {
    static func position(for name: String) -> ScalePosition? {
        scales[name]
    }

    static let scales: [String: ScalePosition] = [
        // MARK: - Am Pentatonic (A, C, D, E, G)

        "Am Pentatonic - Pos 1": ScalePosition(
            frets: [[5, 8], [5, 7], [5, 7], [5, 7], [5, 8], [5, 8]],
            roots: [[5], [], [7], [], [], [5]],
            startFret: 5
        ),
        "Am Pentatonic - Pos 2": ScalePosition(
            frets: [[8, 10], [7, 10], [7, 10], [7, 9], [8, 10], [8, 10]],
            roots: [[], [], [7], [], [10], []],
            startFret: 7
        ),
        "Am Pentatonic - Pos 3": ScalePosition(
            frets: [[10, 12], [10, 12], [10, 12], [9, 12], [10, 13], [10, 12]],
            roots: [[], [12], [], [], [10], []],
            startFret: 9, fretCount: 5
        ),
        "Am Pentatonic - Pos 4": ScalePosition(
            frets: [[12, 15], [12, 15], [12, 14], [12, 14], [13, 15], [12, 15]],
            roots: [[], [12], [], [14], [], []],
            startFret: 12
        ),
        "Am Pentatonic - Pos 5": ScalePosition(
            frets: [[15, 17], [15, 17], [14, 17], [14, 17], [15, 17], [15, 17]],
            roots: [[17], [], [], [14], [], [17]],
            startFret: 14
        ),

        // MARK: - Em Pentatonic Open (E, G, A, B, D)

        "Em Pentatonic - Open": ScalePosition(
            frets: [[0, 3], [0, 2], [0, 2], [0, 2], [0, 3], [0, 3]],
            roots: [[0], [], [2], [], [], [0]],
            startFret: 0
        ),

        // MARK: - A Major Pentatonic Pos 1 (A, B, C#, E, F#)

        "A Major Pentatonic - Pos 1": ScalePosition(
            frets: [[5, 7], [4, 7], [4, 7], [4, 6], [5, 7], [5, 7]],
            roots: [[5], [], [7], [], [], [5]],
            startFret: 4
        ),

        // MARK: - G Major Open (G, A, B, C, D, E, F#)

        "G Major - Open": ScalePosition(
            frets: [[0, 2, 3], [0, 2, 3], [0, 2], [0, 2], [0, 1, 3], [0, 2, 3]],
            roots: [[3], [], [], [0], [], [3]],
            startFret: 0
        ),

        // MARK: - C Major Open (C, D, E, F, G, A, B)

        "C Major - Open": ScalePosition(
            frets: [[0, 1, 3], [0, 2, 3], [0, 2, 3], [0, 2], [0, 1, 3], [0, 1, 3]],
            roots: [[], [3], [], [], [1], []],
            startFret: 0
        ),

        // MARK: - Am Natural Minor Open (A, B, C, D, E, F, G)

        "Am Natural Minor - Open": ScalePosition(
            frets: [[0, 1, 3], [0, 2, 3], [0, 2, 3], [0, 2], [0, 1, 3], [0, 1, 3]],
            roots: [[], [0], [], [2], [], []],
            startFret: 0
        ),

        // MARK: - Am Blues Pos 1 (A, C, D, Eb, E, G)

        "Am Blues - Pos 1": ScalePosition(
            frets: [[5, 8], [5, 6, 7], [5, 7], [5, 7, 8], [5, 8], [5, 8]],
            roots: [[5], [], [7], [], [], [5]],
            startFret: 5
        ),

        // MARK: - Em Blues Open (E, G, A, Bb, B, D)

        "Em Blues - Open": ScalePosition(
            frets: [[0, 3], [0, 1, 2], [0, 2], [0, 2, 3], [0, 3], [0, 3]],
            roots: [[0], [], [2], [], [], [0]],
            startFret: 0
        ),

        // MARK: - Major Scales (Open Position)

        "D Major - Open": ScalePosition(
            frets: [[0, 2, 3], [0, 2, 4], [0, 2, 4], [0, 2, 4], [0, 2, 3], [0, 2, 3]],
            roots: [[], [], [0], [], [3], []],
            startFret: 0
        ),
        "A Major - Open": ScalePosition(
            frets: [[0, 2, 4], [0, 2, 4], [0, 2, 4], [1, 2, 4], [0, 2, 3], [0, 2, 4]],
            roots: [[], [0], [], [2], [], []],
            startFret: 0
        ),
        "E Major - Open": ScalePosition(
            frets: [[0, 2, 4], [0, 2, 4], [1, 2, 4], [1, 2, 4], [0, 2, 4], [0, 2, 4]],
            roots: [[0], [], [2], [], [], [0]],
            startFret: 0
        ),
        "F Major - Open": ScalePosition(
            frets: [[0, 1, 3], [0, 1, 3], [0, 2, 3], [0, 2, 3], [1, 3], [0, 1, 3]],
            roots: [[1], [], [3], [], [], [1]],
            startFret: 0
        ),

        // MARK: - Major Scales (Movable Position)

        "Bb Major - Pos 1": ScalePosition(
            frets: [[6, 8], [5, 6, 8], [5, 7, 8], [5, 7, 8], [6, 8], [5, 6, 8]],
            roots: [[6], [], [8], [], [], [6]],
            startFret: 5
        ),
        "Eb Major - Pos 1": ScalePosition(
            frets: [[11, 13], [10, 11, 13], [10, 12, 13], [10, 12, 13], [11, 13], [10, 11, 13]],
            roots: [[11], [], [13], [], [], [11]],
            startFret: 10
        ),

        // MARK: - Minor Scales (Open Position)

        "Em Natural Minor - Open": ScalePosition(
            frets: [[0, 2, 3], [0, 2, 3], [0, 2, 4], [0, 2, 4], [0, 1, 3], [0, 2, 3]],
            roots: [[0], [], [2], [], [], [0]],
            startFret: 0
        ),
        "Dm Natural Minor - Open": ScalePosition(
            frets: [[0, 1, 3], [0, 1, 3], [0, 2, 3], [0, 2, 3], [1, 3], [0, 1, 3]],
            roots: [[], [], [0], [], [3], []],
            startFret: 0
        ),

        // MARK: - Minor Scales (Movable Position)

        "Bm Natural Minor - Pos 1": ScalePosition(
            frets: [[7, 9, 10], [7, 9, 10], [7, 9], [7, 9], [7, 8, 10], [7, 9, 10]],
            roots: [[7], [], [9], [], [], [7]],
            startFret: 7
        ),
        "F#m Natural Minor - Pos 1": ScalePosition(
            frets: [[2, 4, 5], [2, 4, 5], [2, 4], [2, 4], [2, 3, 5], [2, 4, 5]],
            roots: [[2], [], [4], [], [], [2]],
            startFret: 2
        ),
        "Gm Natural Minor - Pos 1": ScalePosition(
            frets: [[3, 5, 6], [3, 5, 6], [3, 5], [3, 5], [3, 4, 6], [3, 5, 6]],
            roots: [[3], [], [5], [], [], [3]],
            startFret: 3
        ),
        "Cm Natural Minor - Pos 1": ScalePosition(
            frets: [[8, 10, 11], [8, 10, 11], [8, 10], [8, 10], [8, 9, 11], [8, 10, 11]],
            roots: [[8], [], [10], [], [], [8]],
            startFret: 8
        ),

        // MARK: - Minor Pentatonics (Movable Pos 1)

        "Dm Pentatonic - Pos 1": ScalePosition(
            frets: [[10, 13], [10, 12], [10, 12], [10, 12], [10, 13], [10, 13]],
            roots: [[10], [], [12], [], [], [10]],
            startFret: 10
        ),
        "Gm Pentatonic - Pos 1": ScalePosition(
            frets: [[3, 6], [3, 5], [3, 5], [3, 5], [3, 6], [3, 6]],
            roots: [[3], [], [5], [], [], [3]],
            startFret: 3
        ),
        "Bm Pentatonic - Pos 1": ScalePosition(
            frets: [[7, 10], [7, 9], [7, 9], [7, 9], [7, 10], [7, 10]],
            roots: [[7], [], [9], [], [], [7]],
            startFret: 7
        ),

        // MARK: - Major Pentatonics (Open Position)

        "G Major Pentatonic - Open": ScalePosition(
            frets: [[0, 3], [0, 2], [0, 2], [0, 2, 4], [0, 3], [0, 3]],
            roots: [[3], [], [], [0], [], [3]],
            startFret: 0
        ),
        "E Major Pentatonic - Open": ScalePosition(
            frets: [[0, 2, 4], [2, 4], [2, 4], [1, 4], [0, 2], [0, 2, 4]],
            roots: [[0], [], [2], [], [], [0]],
            startFret: 0
        ),
        "C Major Pentatonic - Open": ScalePosition(
            frets: [[0, 3], [0, 3], [0, 2], [0, 2], [1, 3], [0, 3]],
            roots: [[], [3], [], [], [1], []],
            startFret: 0
        ),

        // MARK: - Major Pentatonics (Movable Pos 1)

        "D Major Pentatonic - Pos 1": ScalePosition(
            frets: [[10, 12], [9, 12], [9, 12], [9, 11], [10, 12], [10, 12]],
            roots: [[10], [], [12], [], [], [10]],
            startFret: 9
        ),
        "C Major Pentatonic - Pos 1": ScalePosition(
            frets: [[8, 10], [7, 10], [7, 10], [7, 9], [8, 10], [8, 10]],
            roots: [[8], [], [10], [], [], [8]],
            startFret: 7
        ),
    ]
}
