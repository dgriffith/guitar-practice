import SwiftUI

struct MetronomeIndicatorView: View {
    let beatsPerMeasure: Int
    let currentBeat: Int
    let bpm: Int
    let originalBPM: Int?
    let isModified: Bool
    let timeSignature: TimeSignature
    let swing: Double
    let isInDropout: Bool
    let onAdjustBPM: (Int) -> Void
    let onResetBPM: () -> Void

    var body: some View {
        VStack(spacing: Theme.mediumSpacing) {
            // BPM controls
            HStack(spacing: Theme.mediumSpacing) {
                Button { onAdjustBPM(-5) } label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("-5 BPM")

                Button { onAdjustBPM(-1) } label: {
                    Image(systemName: "minus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("-1 BPM")

                VStack(spacing: 0) {
                    Text("\(bpm)")
                        .font(.system(size: 28, weight: .medium, design: .monospaced))
                    Text("BPM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 60)

                Button { onAdjustBPM(1) } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("+1 BPM")

                Button { onAdjustBPM(5) } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("+5 BPM")
            }

            // Show original BPM and reset if modified
            if isModified, let original = originalBPM {
                HStack(spacing: Theme.smallSpacing) {
                    Text("was \(original)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Reset") {
                        onResetBPM()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }

            // Time signature + swing label
            HStack(spacing: Theme.spacing) {
                Text("\(timeSignature.beatsPerMeasure)/\(timeSignature.beatUnit)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if swing > 0.5 {
                    Text("Swing \(Int(swing * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }

            // Dropout indicator
            if isInDropout {
                Text("Keep time!")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .transition(.opacity)
            }

            // Beat indicator dots
            HStack(spacing: 8) {
                ForEach(1...beatsPerMeasure, id: \.self) { beat in
                    if isInDropout {
                        Circle()
                            .stroke(beatColor(for: beat), lineWidth: 2)
                            .frame(
                                width: beat == 1 ? 20 : 16,
                                height: beat == 1 ? 20 : 16
                            )
                            .scaleEffect(beat == currentBeat ? 1.3 : 1.0)
                            .animation(.easeOut(duration: 0.08), value: currentBeat)
                    } else {
                        Circle()
                            .fill(beatColor(for: beat))
                            .frame(
                                width: beat == 1 ? 20 : 16,
                                height: beat == 1 ? 20 : 16
                            )
                            .scaleEffect(beat == currentBeat ? 1.3 : 1.0)
                            .animation(.easeOut(duration: 0.08), value: currentBeat)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isInDropout)
        }
        .padding(Theme.mediumSpacing)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.largeCornerRadius))
    }

    private func beatColor(for beat: Int) -> Color {
        if beat == currentBeat {
            return beat == 1 ? .accentColor : .accentColor.opacity(0.8)
        }
        return .secondary.opacity(0.25)
    }
}
