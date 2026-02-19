import SwiftUI

struct StepListView: View {
    let steps: [PracticeStep]
    let currentStepIndex: Int
    let onSelectStep: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    StepRowView(
                        step: step,
                        index: index,
                        isCurrent: index == currentStepIndex,
                        isCompleted: index < currentStepIndex
                    )
                    .id(index)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectStep(index) }
                }
            }
            .listStyle(.sidebar)
            .onChange(of: currentStepIndex) { _, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(currentStepIndex, anchor: .center)
            }
        }
    }
}

// MARK: - StepRowView

struct StepRowView: View {
    let step: PracticeStep
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: Theme.mediumSpacing) {
            // Step number / status indicator
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 28, height: 28)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(isCurrent ? .white : .secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(step.name)
                    .font(isCurrent ? .body.bold() : .body)
                    .foregroundStyle(isCurrent ? .primary : (isCompleted ? .secondary : .primary))

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

            if isCurrent {
                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(
            isCurrent
                ? Color.blue.opacity(0.1)
                : Color.clear
        )
    }

    private var circleColor: Color {
        if isCurrent { return .accentColor }
        if isCompleted { return .green }
        return .secondary.opacity(0.2)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if secs == 0 { return "\(mins) min" }
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
