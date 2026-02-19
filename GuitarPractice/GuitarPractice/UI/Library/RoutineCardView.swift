import SwiftUI

struct RoutineCardView: View {
    let routine: PracticeRoutine

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacing) {
            HStack {
                Text(routine.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(routine.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.categoryColor(routine.category).opacity(0.2))
                    .foregroundStyle(Theme.categoryColor(routine.category))
                    .clipShape(Capsule())
            }

            Text(routine.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: Theme.mediumSpacing) {
                Label("\(routine.stepCount) steps", systemImage: "list.number")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let duration = routine.estimatedDurationMinutes {
                    Label("\(duration) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !routine.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(routine.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(Theme.mediumSpacing)
    }
}
