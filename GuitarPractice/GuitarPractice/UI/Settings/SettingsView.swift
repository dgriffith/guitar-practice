import SwiftUI

struct SettingsView: View {
    @AppStorage("stepPauseEnabled") private var stepPauseEnabled = true
    @AppStorage("stepPauseDuration") private var stepPauseDuration = 5
    @AppStorage("dropoutEnabled") private var dropoutEnabled = false
    @AppStorage("dropoutPlayMeasures") private var dropoutPlayMeasures = 4
    @AppStorage("dropoutMuteMeasures") private var dropoutMuteMeasures = 2

    var body: some View {
        Form {
            Section("Step Countdown") {
                Toggle("Countdown before each step", isOn: $stepPauseEnabled)

                if stepPauseEnabled {
                    Stepper(
                        "Duration: \(stepPauseDuration) second\(stepPauseDuration == 1 ? "" : "s")",
                        value: $stepPauseDuration,
                        in: 1...10
                    )
                }
            }

            Section("Rhythm Training") {
                Toggle("Metronome dropout", isOn: $dropoutEnabled)

                if dropoutEnabled {
                    Stepper(
                        "Play: \(dropoutPlayMeasures) measure\(dropoutPlayMeasures == 1 ? "" : "s")",
                        value: $dropoutPlayMeasures,
                        in: 1...8
                    )

                    Stepper(
                        "Mute: \(dropoutMuteMeasures) measure\(dropoutMuteMeasures == 1 ? "" : "s")",
                        value: $dropoutMuteMeasures,
                        in: 1...4
                    )

                    Text("The metronome will go silent for \(dropoutMuteMeasures) measure\(dropoutMuteMeasures == 1 ? "" : "s") after every \(dropoutPlayMeasures). Keep time internally!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }
}
