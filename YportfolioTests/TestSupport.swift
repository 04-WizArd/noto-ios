import Foundation
import SwiftData
@testable import Yportfolio

/// Manually advanced clock, injected into `NotesViewModel`.
final class TestClock {
    var now: Date

    init(_ start: Date = Date(timeIntervalSinceReferenceDate: 800_000_000)) {
        now = start
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}

/// Isolated SwiftData stack for one test: a fresh in-memory store each time.
@MainActor
struct NotesFixture {
    let container: ModelContainer
    let context: ModelContext
    let clock: TestClock
    let viewModel: NotesViewModel

    init() throws {
        container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        let clock = TestClock()
        self.clock = clock
        viewModel = NotesViewModel(modelContext: context, now: { clock.now })
    }

    /// Reads through a *new* context, so only what was actually saved is visible.
    func fetchSavedNotes() throws -> [Note] {
        try ModelContext(container).fetch(FetchDescriptor<Note>())
    }

    /// Creates a note through the view model, gives it a title and saves it
    /// (the normal "edit then leave the editor" path).
    func savedNote(_ title: String) throws -> Note {
        let note = viewModel.createNote()
        note.title = title
        try viewModel.finishEditing(note)
        return note
    }

    /// Inserts a note with explicit dates (for sort tests).
    @discardableResult
    func insertNote(
        title: String = "Note", body: String = "", isPinned: Bool = false,
        createdAt: Date, modifiedAt: Date? = nil
    ) -> Note {
        let note = Note(title: title, body: body, isPinned: isPinned, createdAt: createdAt, modifiedAt: modifiedAt)
        context.insert(note)
        return note
    }
}
