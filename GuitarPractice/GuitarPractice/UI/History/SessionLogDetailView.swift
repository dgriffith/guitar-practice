import SwiftUI

struct SessionLogDetailView: View {
    let log: SessionLog

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: Theme.mediumSpacing) {
                HStack {
                    Text(log.routineName)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    Text(log.routineCategory.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.categoryColor(log.routineCategory).opacity(0.2))
                        .foregroundStyle(Theme.categoryColor(log.routineCategory))
                        .clipShape(Capsule())
                }

                Text(log.formattedDate)
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: Theme.largeSpacing) {
                    Label(log.formattedDuration, systemImage: "clock")
                    Label("\(log.stepsCompleted) of \(log.totalSteps) steps", systemImage: "checkmark.circle")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .padding(Theme.extraLargeSpacing)

            Divider()

            // Step breakdown
            List {
                ForEach(Array(log.stepLogs.enumerated()), id: \.offset) { index, stepLog in
                    HStack(spacing: Theme.mediumSpacing) {
                        Image(systemName: stepLog.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(stepLog.completed ? .green : .secondary.opacity(0.4))
                            .font(.body)

                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stepLog.stepName)
                                .font(.body)
                                .fontWeight(.medium)

                            HStack(spacing: Theme.spacing) {
                                if stepLog.timeSpent > 0 {
                                    Label(formatDuration(stepLog.timeSpent), systemImage: "timer")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let bpm = stepLog.bpmUsed {
                                    HStack(spacing: 2) {
                                        Label("\(bpm) BPM", systemImage: "metronome")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)

                                        if let original = stepLog.originalBPM, bpm != original {
                                            Text("(was \(original))")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.inset)
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        if mins == 0 {
            return "\(secs)s"
        }
        return secs == 0 ? "\(mins) min" : "\(mins):\(String(format: "%02d", secs))"
    }
}
