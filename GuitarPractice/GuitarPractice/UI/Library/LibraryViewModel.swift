import Foundation
import Observation

@Observable
class LibraryViewModel {
    var routines: [PracticeRoutine] = []
    var searchText: String = ""
    var selectedCategory: RoutineCategory?

    var filteredRoutines: [PracticeRoutine] {
        routines.filter { routine in
            let matchesSearch = searchText.isEmpty
                || routine.name.localizedCaseInsensitiveContains(searchText)
                || routine.description.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil
                || routine.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    private let loader: RoutineLoader

    init(loader: RoutineLoader = RoutineLoader()) {
        self.loader = loader
    }

    func loadRoutines() {
        routines = loader.loadAllRoutines()
    }
}
