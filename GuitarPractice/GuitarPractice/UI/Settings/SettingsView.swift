import SwiftUI

struct SettingsView: View {
    @AppStorage("stepPauseEnabled") private var stepPauseEnabled = true
    @AppStorage("stepPauseDuration") private var stepPauseDuration = 5

    var body: some View {
        Form {
            Section("Step Transitions") {
                Toggle("Pause between steps", isOn: $stepPauseEnabled)

                if stepPauseEnabled {
                    Stepper(
                        "Countdown: \(stepPauseDuration) second\(stepPauseDuration == 1 ? "" : "s")",
                        value: $stepPauseDuration,
                        in: 1...10
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350)
        .fixedSize()
    }
}
