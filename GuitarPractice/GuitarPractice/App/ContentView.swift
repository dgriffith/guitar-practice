import SwiftUI

enum SidebarTab: String, CaseIterable {
    case routines = "Routines"
    case history = "History"
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var libraryViewModel = LibraryViewModel()
    @State private var sidebarTab: SidebarTab = .routines

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView {
            VStack(spacing: 0) {
                Picker("View", selection: $sidebarTab) {
                    ForEach(SidebarTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.mediumSpacing)
                .padding(.vertical, Theme.spacing)

                switch sidebarTab {
                case .routines:
                    LibraryView(
                        viewModel: libraryViewModel,
                        selectedRoutine: $appState.selectedRoutine
                    )
                case .history:
                    SessionLogListView()
                }
            }
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 450)
            .onChange(of: sidebarTab) {
                appState.selectedRoutine = nil
                appState.selectedSessionLog = nil
            }
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
        } else if let log = appState.selectedSessionLog {
            SessionLogDetailView(log: log)
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: Theme.largeSpacing) {
            Image(systemName: sidebarTab == .routines ? "guitars" : "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text(sidebarTab == .routines ? "Select a practice routine" : "Select a session")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(sidebarTab == .routines
                 ? "Choose a routine from the sidebar to preview and start practicing."
                 : "Select a completed session to view details.")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
