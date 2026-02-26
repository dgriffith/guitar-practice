import SwiftUI
import UniformTypeIdentifiers

enum SidebarTab: String, CaseIterable {
    case routines = "Routines"
    case history = "History"
}

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var libraryViewModel = LibraryViewModel()
    @State private var sidebarTab: SidebarTab = .routines
    @State private var showImportError = false
    @State private var isDropTargeted = false

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.isTunerActive.toggle()
                    if appState.isTunerActive {
                        appState.tunerEngine.start()
                    } else {
                        appState.tunerEngine.stop()
                    }
                } label: {
                    Image(systemName: "tuningfork")
                        .foregroundStyle(appState.isTunerActive ? Color.accentColor : .secondary)
                }
                .help(appState.isTunerActive ? "Hide tuner" : "Show tuner")
            }
        }
        .onDrop(of: [.json, .fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: Theme.largeCornerRadius)
                    .stroke(Color.accentColor, lineWidth: 3)
                    .background(Color.accentColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.largeCornerRadius))
                    .overlay {
                        VStack(spacing: Theme.spacing) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.largeTitle)
                            Text("Drop to import routine")
                                .font(.headline)
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: appState.importError) {
            showImportError = appState.importError != nil
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK") { appState.importError = nil }
        } message: {
            Text(appState.importError ?? "")
        }
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
        } else if appState.isTunerActive {
            TunerView(tunerEngine: appState.tunerEngine)
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

    // MARK: - Drag and Drop

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                handled = true
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                    guard let data = data as? Data,
                          let urlString = String(data: data, encoding: .utf8),
                          let url = URL(string: urlString),
                          url.pathExtension.lowercased() == "json" else { return }
                    DispatchQueue.main.async {
                        appState.importRoutines(from: [url]) {
                            sidebarTab = .routines
                            libraryViewModel.loadRoutines()
                        }
                    }
                }
            }
        }
        return handled
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
