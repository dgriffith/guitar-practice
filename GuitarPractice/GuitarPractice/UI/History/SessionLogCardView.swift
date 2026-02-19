import SwiftUI

struct SessionLogCardView: View {
    let log: SessionLog

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack {
                Text(log.routineName)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(log.routineCategory.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.categoryColor(log.routineCategory).opacity(0.2))
                    .foregroundStyle(Theme.categoryColor(log.routineCategory))
                    .clipShape(Capsule())
            }

            HStack(spacing: Theme.mediumSpacing) {
                Label(log.formattedDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(log.stepsCompleted)/\(log.totalSteps) steps", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(log.relativeDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.mediumSpacing)
    }
}
