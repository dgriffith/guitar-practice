import SwiftUI

struct TransportControlsView: View {
    let state: SessionState
    let canGoBack: Bool
    let isLastStep: Bool

    let onBack: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: Theme.extraLargeSpacing) {
            // Back
            Button(action: onBack) {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(!canGoBack)
            .keyboardShortcut(.leftArrow, modifiers: [])
            .help("Previous step (Left Arrow)")

            // Play/Pause
            Button(action: onPlayPause) {
                Image(systemName: playPauseIcon)
                    .font(.system(size: 36))
                    .frame(width: 60, height: 60)
                    .background(playPauseBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.space, modifiers: [])
            .help(playPauseHelp)

            // Next / Done
            Button(action: onNext) {
                Image(systemName: isLastStep ? "checkmark.circle.fill" : "forward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.rightArrow, modifiers: [])
            .help(isLastStep ? "Finish session (Right Arrow)" : "Next step (Right Arrow)")
        }
        .padding(Theme.largeSpacing)
    }

    private var playPauseIcon: String {
        switch state {
        case .playing: "pause.fill"
        case .stepComplete: "forward.fill"
        case .completed: "checkmark"
        default: "play.fill"
        }
    }

    private var playPauseBackground: Color {
        switch state {
        case .completed: .green.opacity(0.2)
        case .stepComplete: .orange.opacity(0.2)
        default: .accentColor.opacity(0.15)
        }
    }

    private var playPauseHelp: String {
        switch state {
        case .playing: "Pause (Space)"
        case .paused: "Resume (Space)"
        case .stepComplete: "Next step (Space)"
        case .completed: "Session complete"
        default: "Start (Space)"
        }
    }
}
