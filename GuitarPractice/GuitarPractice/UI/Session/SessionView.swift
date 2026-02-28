import SwiftUI

struct SessionView: View {
    @Bindable var viewModel: SessionViewModel
    let onExit: () -> Void
    let onSaveRoutine: (PracticeRoutine) -> Void

    @State private var showExitConfirmation = false
    @State private var showSaveConfirmation = false
    @State private var saveError: String?
    @State private var showingVoiceCommand = false
    @State private var stepListHeight: CGFloat = 200
    @State private var dragStartHeight: CGFloat?

    var body: some View {
        VStack(spacing: 0) {
            // Header: progress + exit button
            HStack {
                ProgressBarView(
                    stepLabel: viewModel.stepLabel,
                    progress: viewModel.progressFraction,
                    state: viewModel.state
                )

                // Voice command indicator
                voiceIndicator

                Button(action: { confirmExit() }) {
                    Image(systemName: "xmark.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                .help("End session (Esc)")
            }
            .padding(.horizontal, Theme.extraLargeSpacing)
            .padding(.top, Theme.largeSpacing)
            .padding(.bottom, Theme.spacing)

            Divider()

            if viewModel.state == .completed {
                completedView
            } else {
                activeSessionView
            }
        }
        .alert("End Practice Session?", isPresented: $showExitConfirmation) {
            Button("Continue Practicing", role: .cancel) {}
            Button("End Session", role: .destructive) { onExit() }
        } message: {
            Text("Your progress in this session will not be saved.")
        }
        .alert("Save BPM Changes?", isPresented: $showSaveConfirmation) {
            Button("Don't Save") { onExit() }
            Button("Save") {
                onSaveRoutine(viewModel.routineWithBPMChanges())
                onExit()
            }
        } message: {
            let changes = viewModel.bpmChangeSummary
            Text("You adjusted the tempo on \(changes.count) step\(changes.count == 1 ? "" : "s"):\n\n\(changes.joined(separator: "\n"))")
        }
    }

    // MARK: - Active Session

    @ViewBuilder
    private var activeSessionView: some View {
        HSplitView {
            // Left: step list + current step detail
            VStack(spacing: 0) {
                StepListView(
                    steps: viewModel.steps,
                    currentStepIndex: viewModel.currentStepIndex,
                    onSelectStep: { viewModel.goToStep($0) }
                )
                .frame(height: stepListHeight)

                // Draggable divider
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.secondary.opacity(0.4))
                            .frame(width: 36, height: 3)
                        Spacer()
                    }
                    .padding(.vertical, 3)
                    Divider()
                }
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if dragStartHeight == nil {
                                dragStartHeight = stepListHeight
                            }
                            let newHeight = (dragStartHeight ?? stepListHeight) + value.translation.height
                            stepListHeight = max(100, min(newHeight, 500))
                        }
                        .onEnded { _ in
                            dragStartHeight = nil
                        }
                )

                // Current step detail
                ZStack {
                    StepView(
                        name: viewModel.stepName,
                        instructions: viewModel.instructions,
                        notes: viewModel.notes,
                        chords: viewModel.chords,
                        currentChordIndex: viewModel.currentChordIndex,
                        images: viewModel.images,
                        scales: viewModel.scales,
                        strumPattern: viewModel.strumPattern,
                        currentRawBeat: viewModel.rawBeat,
                        isMetronomePlaying: viewModel.isMetronomePlaying,
                        beatsPerMeasure: viewModel.beatsPerMeasure,
                        subdivisions: viewModel.currentSubdivisions
                    )
                    .padding(Theme.largeSpacing)

                    if case .countdown(let remaining) = viewModel.state {
                        countdownOverlay(remaining: remaining)
                    }
                }
                .frame(minHeight: 100)
            }
            .frame(minWidth: 300)

            // Right: timer, metronome, controls
            VStack(spacing: Theme.largeSpacing) {
                Spacer()

                TimerView(
                    timeDisplay: viewModel.timeDisplay,
                    label: viewModel.timeLabel,
                    isTimed: viewModel.isTimed,
                    state: viewModel.state
                )

                if viewModel.state == .stepComplete {
                    Text("Step complete! Press Next to continue.")
                        .font(.callout)
                        .foregroundStyle(.orange)
                        .fontWeight(.medium)
                }

                if viewModel.isMetronomeActive, let ts = viewModel.currentTimeSignature {
                    MetronomeIndicatorView(
                        beatsPerMeasure: viewModel.beatsPerMeasure,
                        currentBeat: viewModel.currentBeat,
                        bpm: viewModel.currentBPM,
                        originalBPM: viewModel.originalBPM,
                        isModified: viewModel.currentStepBPMModified,
                        timeSignature: ts,
                        swing: viewModel.currentSwing,
                        isInDropout: viewModel.isInDropout,
                        onAdjustBPM: { viewModel.adjustBPM(by: $0) },
                        onResetBPM: { viewModel.resetBPM() }
                    )
                }

                Spacer()

                TransportControlsView(
                    state: viewModel.state,
                    canGoBack: viewModel.canGoBack,
                    isLastStep: viewModel.isLastStep,
                    onBack: { viewModel.previousStep() },
                    onPlayPause: { viewModel.togglePlayPause() },
                    onNext: { viewModel.nextStep() },
                    onSkip: { viewModel.skipStep() }
                )
            }
            .frame(minWidth: 280)
            .padding(Theme.largeSpacing)
        }
    }

    // MARK: - Completed View

    @ViewBuilder
    private var completedView: some View {
        VStack(spacing: Theme.extraLargeSpacing) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Session Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("You finished \(viewModel.routineName)")
                .font(.title3)
                .foregroundStyle(.secondary)

            if viewModel.hasBPMChanges {
                VStack(spacing: Theme.spacing) {
                    Text("Tempo changes made:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(viewModel.bpmChangeSummary, id: \.self) { change in
                        Text(change)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Theme.mediumSpacing)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }

            HStack(spacing: Theme.largeSpacing) {
                Button("Back to Library") {
                    if viewModel.hasBPMChanges {
                        showSaveConfirmation = true
                    } else {
                        onExit()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Voice Indicator

    @ViewBuilder
    private var voiceIndicator: some View {
        HStack(spacing: 4) {
            if showingVoiceCommand, let command = viewModel.lastVoiceCommand {
                Text(command.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                    .transition(.opacity)
            }

            Button(action: { viewModel.toggleVoice() }) {
                Image(systemName: viewModel.isVoiceActive ? "mic.fill" : "mic.slash")
                    .font(.body)
                    .foregroundStyle(viewModel.isVoiceActive ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .help(viewModel.isVoiceActive ? "Voice commands active (tap to mute)" : "Enable voice commands")
        }
        .onChange(of: viewModel.lastVoiceCommandTime) {
            withAnimation(.easeIn(duration: 0.15)) {
                showingVoiceCommand = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showingVoiceCommand = false
                }
            }
        }
    }

    // MARK: - Countdown Overlay

    @ViewBuilder
    private func countdownOverlay(remaining: Int) -> some View {
        ZStack {
            Color.black.opacity(0.6)

            VStack(spacing: Theme.largeSpacing) {
                Text("Get ready...")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(remaining)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: remaining)

                Text(viewModel.stepName)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))

                Button("Skip") {
                    viewModel.skipCountdown()
                }
                .buttonStyle(.bordered)
                .tint(.white)
                .controlSize(.small)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .onTapGesture {
            viewModel.skipCountdown()
        }
    }

    // MARK: - Helpers

    private func confirmExit() {
        if viewModel.state == .completed {
            if viewModel.hasBPMChanges {
                showSaveConfirmation = true
            } else {
                onExit()
            }
        } else {
            showExitConfirmation = true
        }
    }
}
