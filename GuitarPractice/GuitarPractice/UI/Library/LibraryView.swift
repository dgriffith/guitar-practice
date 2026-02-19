import SwiftUI

struct LibraryView: View {
    @Environment(AppState.self) private var appState
    @Bindable var viewModel: LibraryViewModel
    @Binding var selectedRoutine: PracticeRoutine?

    var body: some View {
        List(viewModel.filteredRoutines, selection: $selectedRoutine) { routine in
            RoutineCardView(routine: routine)
                .tag(routine)
                .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
        }
        .listStyle(.sidebar)
        .searchable(text: $viewModel.searchText, prompt: "Search routines")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.showImportPanel {
                        viewModel.loadRoutines()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Import routine from file")
            }

            ToolbarItem(placement: .automatic) {
                Picker("Category", selection: categoryBinding) {
                    Text("All").tag("")
                    ForEach(RoutineCategory.allCases) { category in
                        Text(category.displayName).tag(category.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .onAppear {
            viewModel.loadRoutines()
        }
    }

    private var categoryBinding: Binding<String> {
        Binding(
            get: { viewModel.selectedCategory?.rawValue ?? "" },
            set: { newValue in
                viewModel.selectedCategory = newValue.isEmpty ? nil : RoutineCategory(rawValue: newValue)
            }
        )
    }
}
