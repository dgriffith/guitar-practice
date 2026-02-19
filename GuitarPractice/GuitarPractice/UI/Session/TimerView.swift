import SwiftUI

struct TimerView: View {
    let timeDisplay: String
    let label: String
    let isTimed: Bool
    let state: SessionState

    var body: some View {
        VStack(spacing: Theme.smallSpacing) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
                .tracking(1)

            Text(timeDisplay)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(timerColor)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: timeDisplay)
        }
        .padding(Theme.largeSpacing)
    }

    private var timerColor: Color {
        switch state {
        case .stepComplete:
            return .orange
        case .completed:
            return .green
        case .paused:
            return .secondary
        default:
            return .primary
        }
    }
}
