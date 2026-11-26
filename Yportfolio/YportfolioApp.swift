import SwiftUI
import SwiftData

@main
struct YportfolioApp: App {

    private let modelContainer: ModelContainer
    @State private var notesViewModel: NotesViewModel

    init() {
        let container = Self.makeModelContainer()
        let viewModel = NotesViewModel(modelContext: container.mainContext)
        do {
            try viewModel.deleteEmptyNotes()
        } catch {
            viewModel.report(error)
        }
        modelContainer = container
        _notesViewModel = State(initialValue: viewModel)
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .environment(notesViewModel)
    }

    // MARK: - SwiftData container

    /// The app cannot work without its store, and recovering from an unreadable
    /// store (reset, migration plan, user-facing recovery screen) is a separate
    /// strategy not designed yet — so a failure here still stops the app.
    private static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: Note.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
