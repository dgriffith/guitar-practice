# Guitar Practice

A native macOS app for structured guitar practice sessions with a built-in metronome, voice commands, and chord diagrams.

## Features

### Practice Routines
- **Bundled routines** for warmups, chord changes, scales, fingerpicking, and strumming patterns
- **Step-by-step sessions** with timed and untimed steps
- **JSON-based** routine format — easy to create and share custom routines
- User routines saved to `~/Library/Application Support/GuitarPractice/Routines/`

### Metronome
- Precise audio metronome using AVAudioEngine with self-timing beat buffers
- Supports any time signature (4/4, 3/4, 6/8, etc.) and subdivisions
- Accented downbeats with quieter subdivision clicks
- Visual beat indicator with per-beat highlighting
- Adjust BPM on the fly (+/- 1 or 5) with optional save back to the routine

### Voice Commands
Hands-free control using speech recognition — both hands stay on the guitar:

| Command | Trigger Words |
|---------|--------------|
| Start/Resume | "start", "go", "play", "resume" |
| Pause | "pause", "stop", "wait" |
| Next Step | "next", "skip" |
| Previous Step | "back", "previous" |
| Restart Step | "restart", "again", "repeat" |
| Speed Up | "faster", "fast", "speed up" |
| Slow Down | "slower", "slow", "slow down" |

### Chord Diagrams
- Fretboard diagrams rendered programmatically for each chord in a progression
- Shows finger positions, open/muted strings, barre chords, and fret numbers
- Active chord highlighted and scaled up as it cycles with the metronome
- 13 built-in chords: A, Am, Am7, C, Cmaj7, Cadd9, D, Dm, E, Em, F, G, G/B

### Step Transition Countdown
- Optional pause between steps (default 5 seconds) so you can reposition your hands
- Configurable in Settings (Cmd+,): toggle on/off and set duration 1-10 seconds
- Skip the countdown by clicking, pressing Space, or saying "start"

### Images
- Steps can reference image files (chord sheets, tab diagrams, etc.)
- Loads from bundle, app support directory, or absolute paths
- Specified via `"images": ["filename.png"]` in the step JSON

## Building

Requires **Xcode 15+** and **macOS 14.0 (Sonoma)** or later.

1. Open `GuitarPractice/GuitarPractice.xcodeproj` in Xcode
2. Build and run (Cmd+R)

The app uses the App Sandbox with microphone access for voice commands and speech recognition.

## Custom Routines

Create a JSON file following this schema and place it in `~/Library/Application Support/GuitarPractice/Routines/`:

```json
{
  "name": "My Routine",
  "description": "A description of the routine.",
  "category": "chords",
  "estimatedDurationMinutes": 15,
  "tags": ["beginner"],
  "steps": [
    {
      "name": "Step Name",
      "instructions": "What to practice.",
      "duration": 120,
      "metronome": {
        "bpm": 80,
        "timeSignature": { "beatsPerMeasure": 4, "beatUnit": 4 },
        "accentDownbeat": true,
        "subdivisions": 1
      },
      "notes": "Optional tip.",
      "chords": ["G", "C", "D", "G"],
      "measuresPerChord": 1,
      "images": ["chord-sheet.png"]
    }
  ]
}
```

**Fields:**
- `duration` — Step length in seconds. Omit or set to `null` for untimed steps.
- `metronome` — Omit for steps without a metronome.
- `chords` — Chord names that cycle with the metronome. Omit if not needed.
- `measuresPerChord` — Measures before advancing to the next chord (default: 1).
- `images` — Image filenames to display. Place images in `~/Library/Application Support/GuitarPractice/Images/`.
- `category` — One of: `warmup`, `chords`, `scales`, `fingerpicking`, `strumming`, `theory`, `songs`, `custom`.

## Architecture

Swift + SwiftUI with the `@Observable` macro. MVVM pattern.

```
GuitarPractice/
  App/            — Entry point, app state, root navigation
  Audio/          — MetronomeEngine, ClickSoundGenerator, SoundPlayer, SpeechRecognizer
  Domain/
    Models/       — PracticeRoutine, PracticeSession, ChordLibrary
    Services/     — RoutineLoader (bundle + user directory)
  UI/
    Library/      — Routine browsing, filtering, detail view
    Session/      — Active practice session, step display, transport controls
    Settings/     — Preferences panel
    Shared/       — Theme, ChordDiagramView
  Resources/
    Routines/     — Bundled JSON practice routines
    Assets.xcassets/
```

## License

MIT
