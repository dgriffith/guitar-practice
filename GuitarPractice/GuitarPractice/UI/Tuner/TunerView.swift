import SwiftUI

struct TunerView: View {
    let tunerEngine: TunerEngine

    private var noteColor: Color {
        guard tunerEngine.detectedNote != nil else { return .secondary }
        let absCents = abs(tunerEngine.centsOffset)
        if absCents < 5 { return .green }
        if absCents < 15 { return .yellow }
        if absCents < 30 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: Theme.extraLargeSpacing) {
            Spacer()

            // Note display
            VStack(spacing: Theme.smallSpacing) {
                if let note = tunerEngine.detectedNote, let octave = tunerEngine.detectedOctave {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(note)
                            .font(.system(size: 96, weight: .bold, design: .rounded))
                            .foregroundStyle(noteColor)
                        Text("\(octave)")
                            .font(.system(size: 36, weight: .medium, design: .rounded))
                            .foregroundStyle(noteColor.opacity(0.7))
                    }
                    .animation(.easeOut(duration: 0.1), value: note)
                    .animation(.easeOut(duration: 0.1), value: octave)
                } else {
                    Text("—")
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.3))
                }

                if let freq = tunerEngine.detectedFrequency {
                    Text(String(format: "%.1f Hz", freq))
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text(tunerEngine.isActive ? "Play a note..." : "Tuner off")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
            }

            // Cents indicator
            TunerIndicatorView(
                centsOffset: tunerEngine.centsOffset,
                isActive: tunerEngine.detectedNote != nil
            )
            .frame(maxWidth: 400)
            .padding(.horizontal, Theme.extraLargeSpacing)

            // Guitar string reference
            if tunerEngine.isActive {
                HStack(spacing: Theme.largeSpacing) {
                    ForEach(guitarStrings, id: \.note) { string in
                        VStack(spacing: 2) {
                            Text(string.note)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(isDetectedString(string) ? noteColor : .secondary)
                            Text(string.label)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 36)
                        .padding(.vertical, Theme.spacing)
                        .background(
                            isDetectedString(string)
                                ? noteColor.opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                }
            }

            Spacer()

            // Toggle button
            Button {
                if tunerEngine.isActive {
                    tunerEngine.stop()
                } else {
                    tunerEngine.start()
                }
            } label: {
                Label(
                    tunerEngine.isActive ? "Stop Tuner" : "Start Tuner",
                    systemImage: tunerEngine.isActive ? "stop.fill" : "tuningfork"
                )
            }
            .buttonStyle(.borderedProminent)
            .tint(tunerEngine.isActive ? .red : .accentColor)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            tunerEngine.stop()
        }
    }

    // MARK: - Guitar Strings

    private struct GuitarString {
        let note: String
        let label: String
        let midiNote: Int
    }

    private let guitarStrings: [GuitarString] = [
        GuitarString(note: "E2", label: "6th", midiNote: 40),
        GuitarString(note: "A2", label: "5th", midiNote: 45),
        GuitarString(note: "D3", label: "4th", midiNote: 50),
        GuitarString(note: "G3", label: "3rd", midiNote: 55),
        GuitarString(note: "B3", label: "2nd", midiNote: 59),
        GuitarString(note: "E4", label: "1st", midiNote: 64),
    ]

    private func isDetectedString(_ string: GuitarString) -> Bool {
        guard let note = tunerEngine.detectedNote, let octave = tunerEngine.detectedOctave else {
            return false
        }
        return string.note == "\(note)\(octave)"
    }
}
