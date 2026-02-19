import Foundation

// MARK: - StepLog

struct StepLog: Codable, Hashable {
    let stepName: String
    let timeSpent: TimeInterval
    let bpmUsed: Int?
    let originalBPM: Int?
    let completed: Bool
}

// MARK: - SessionLog

struct SessionLog: Identifiable, Codable, Hashable {
    let id: UUID
    let routineId: UUID
    let routineName: String
    let routineCategory: RoutineCategory
    let completedAt: Date
    let totalDuration: TimeInterval
    let stepsCompleted: Int
    let totalSteps: Int
    let stepLogs: [StepLog]

    var formattedDuration: String {
        let mins = Int(totalDuration) / 60
        let secs = Int(totalDuration) % 60
        if mins == 0 {
            return "\(secs)s"
        }
        return secs == 0 ? "\(mins) min" : "\(mins)m \(secs)s"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completedAt)
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }
}
