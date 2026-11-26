import SwiftUI
import SwiftData

@main
struct YportfolioApp: App {

    // MARK: - SwiftData container

    var sharedModelContainer: ModelContainer = {
        do {
            let container = try ModelContainer(for: Note.self)
            Note.deleteEmptyNotes(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
