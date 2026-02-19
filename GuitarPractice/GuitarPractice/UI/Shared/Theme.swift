import SwiftUI

enum Theme {
    // MARK: - Colors

    static let accentColor = Color.blue
    static let secondaryText = Color.secondary
    static let background = Color(nsColor: .windowBackgroundColor)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)

    static func categoryColor(_ category: RoutineCategory) -> Color {
        switch category {
        case .warmup: .orange
        case .chords: .blue
        case .scales: .purple
        case .fingerpicking: .green
        case .strumming: .red
        case .theory: .indigo
        case .songs: .pink
        case .custom: .gray
        }
    }

    // MARK: - Spacing

    static let smallSpacing: CGFloat = 4
    static let spacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 12
    static let largeSpacing: CGFloat = 16
    static let extraLargeSpacing: CGFloat = 24

    // MARK: - Corner Radius

    static let cornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 12
}
