import SwiftUI

struct SessionLogListView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Group {
            if appState.sessionLogs.isEmpty {
                VStack(spacing: Theme.mediumSpacing) {
                    Spacer()
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("No sessions yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Complete a practice session to see it here.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(selection: $appState.selectedSessionLog) {
                    ForEach(groupedLogs, id: \.label) { group in
                        Section(group.label) {
                            ForEach(group.logs) { log in
                                SessionLogCardView(log: log)
                                    .tag(log)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            appState.deleteSessionLog(log)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onAppear {
            appState.loadSessionLogs()
        }
    }

    // MARK: - Grouping

    private struct LogGroup {
        let label: String
        let logs: [SessionLog]
    }

    private var groupedLogs: [LogGroup] {
        let calendar = Calendar.current
        let now = Date()

        var today: [SessionLog] = []
        var yesterday: [SessionLog] = []
        var thisWeek: [SessionLog] = []
        var earlier: [SessionLog] = []

        for log in appState.sessionLogs {
            if calendar.isDateInToday(log.completedAt) {
                today.append(log)
            } else if calendar.isDateInYesterday(log.completedAt) {
                yesterday.append(log)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      log.completedAt > weekAgo {
                thisWeek.append(log)
            } else {
                earlier.append(log)
            }
        }

        var groups: [LogGroup] = []
        if !today.isEmpty { groups.append(LogGroup(label: "Today", logs: today)) }
        if !yesterday.isEmpty { groups.append(LogGroup(label: "Yesterday", logs: yesterday)) }
        if !thisWeek.isEmpty { groups.append(LogGroup(label: "This Week", logs: thisWeek)) }
        if !earlier.isEmpty { groups.append(LogGroup(label: "Earlier", logs: earlier)) }
        return groups
    }
}
