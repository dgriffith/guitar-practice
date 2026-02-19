import SwiftUI

struct RoutineDetailView: View {
    @Environment(AppState.self) private var appState
    let routine: PracticeRoutine
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: Theme.mediumSpacing) {
                HStack {
                    Text(routine.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    Text(routine.category.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.categoryColor(routine.category).opacity(0.2))
                        .foregroundStyle(Theme.categoryColor(routine.category))
                        .clipShape(Capsule())
                }

                Text(routine.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: Theme.largeSpacing) {
                    if let duration = routine.estimatedDurationMinutes {
                        Label("\(duration) minutes", systemImage: "clock")
                    }
                    Label("\(routine.stepCount) steps", systemImage: "list.number")
                    if routine.timedStepCount > 0 {
                        Label("\(routine.timedStepCount) timed", systemImage: "timer")
                    }
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .padding(Theme.extraLargeSpacing)

            Divider()

            // Step list preview
            List {
                ForEach(Array(routine.steps.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: Theme.mediumSpacing) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.name)
                                .font(.body)
                                .fontWeight(.medium)

                            HStack(spacing: Theme.spacing) {
                                if let duration = step.duration {
                                    Label(formatDuration(duration), systemImage: "timer")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Label("Untimed", systemImage: "infinity")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let metronome = step.metronome {
                                    Label("\(metronome.bpm) BPM", systemImage: "metronome")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)

            Divider()

            // Action buttons
            HStack(spacing: Theme.largeSpacing) {
                Spacer()

                Button {
                    appState.exportRoutine(routine)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: onStart) {
                    Label("Start Practice", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Spacer()
            }
            .padding(Theme.extraLargeSpacing)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if secs == 0 {
            return "\(mins) min"
        }
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
