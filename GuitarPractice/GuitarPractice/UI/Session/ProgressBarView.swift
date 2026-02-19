import SwiftUI

struct ProgressBarView: View {
    let stepLabel: String
    let progress: Double
    let state: SessionState

    var body: some View {
        VStack(spacing: Theme.smallSpacing) {
            HStack {
                Text(stepLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if state == .completed {
                    Text("Complete")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: max(0, geometry.size.width * progress), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressColor: Color {
        switch state {
        case .completed: .green
        default: .accentColor
        }
    }
}
