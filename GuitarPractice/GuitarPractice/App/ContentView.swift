import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var libraryViewModel = LibraryViewModel()

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            LibraryView(
                viewModel: libraryViewModel,
                selectedRoutine: $appState.selectedRoutine
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 450)
        } detail: {
            detailView
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    @ViewBuilder
    private var detailView: some View {
        if let session = appState.activeSession {
            SessionView(viewModel: session) {
                appState.endSession()
            } onSaveRoutine: { routine in
                appState.saveRoutine(routine)
                libraryViewModel.loadRoutines()
            }
        } else if let routine = appState.selectedRoutine {
            RoutineDetailView(routine: routine) {
                appState.startSession(for: routine)
            }
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Theme.largeSpacing) {
            Image(systemName: "guitars")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Select a practice routine")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Choose a routine from the sidebar to preview and start practicing.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
