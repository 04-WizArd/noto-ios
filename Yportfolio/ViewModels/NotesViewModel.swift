import Foundation
import SwiftData
import OSLog

/// Business actions on notes.
///
/// Views keep `@Query` for reading and `@Bindable` for editing; every write that
/// has a business rule (dates, empty-note cleanup, deletion, explicit save) goes through here.
///
/// Error strategy: operations that save `throw` so callers know they failed.
/// Views catch and forward to `report(_:)`, which logs and exposes `lastError` to the UI.
/// Unsaved changes are kept in the context (no rollback) so no user text is lost;
/// SwiftData autosave or the next explicit save will retry.
@Observable
final class NotesViewModel {

    /// Last persistence failure, shown by the UI. `nil` when there is nothing to report.
    var lastError: Error?

    @ObservationIgnored private let modelContext: ModelContext
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let logger = Logger(subsystem: "com.jordi.yportfolio", category: "Persistence")

    /// - Parameters:
    ///   - modelContext: context used for all writes (the container's `mainContext` in the app).
    ///   - now: clock, injectable for tests.
    init(modelContext: ModelContext, now: @escaping () -> Date = { .now }) {
        self.modelContext = modelContext
        self.now = now
    }

    // MARK: - Create

    /// Inserts a new empty note. It is not saved yet: if it stays empty,
    /// `finishEditing(_:)` (or the launch cleanup) deletes it.
    @discardableResult
    func createNote(accent: NoteAccent = .random()) -> Note {
        let note = Note(accent: accent, createdAt: now())
        modelContext.insert(note)
        return note
    }

    // MARK: - Edit

    /// Records a real edit of the title or body. `createdAt` is never touched.
    func noteDidChange(_ note: Note) {
        note.modifiedAt = now()
    }

    /// Called when the editor closes. Deletes the note if requested or if it has
    /// no useful content (blank title and body), then saves.
    /// - Returns: `true` if the note was deleted.
    @discardableResult
    func finishEditing(_ note: Note, deleteRequested: Bool = false) throws -> Bool {
        let shouldDelete = deleteRequested || !note.hasContent
        if shouldDelete {
            modelContext.delete(note)
        }
        try save()
        return shouldDelete
    }

    // MARK: - Pin

    /// Pins or unpins a note, then saves.
    /// `modifiedAt` is deliberately left untouched: pinning organises the list,
    /// it is not an edit of the note's content (and must not reorder the date sort).
    func togglePin(_ note: Note) throws {
        note.isPinned.toggle()
        try save()
    }

    // MARK: - Delete

    func delete(_ note: Note) throws {
        try delete([note])
    }

    func delete(_ notes: [Note]) throws {
        for note in notes {
            modelContext.delete(note)
        }
        try save()
    }

    /// Deletes every note without content (e.g. a new note left open when the app was killed).
    /// - Returns: the number of deleted notes.
    @discardableResult
    func deleteEmptyNotes() throws -> Int {
        let emptyNotes = try modelContext.fetch(FetchDescriptor<Note>()).filter { !$0.hasContent }
        try delete(emptyNotes)
        return emptyNotes.count
    }

    // MARK: - Errors

    /// Logs a failed operation and exposes it to the UI.
    func report(_ error: Error) {
        logger.error("Persistence error: \(String(describing: error), privacy: .public)")
        lastError = error
    }

    /// Runs an operation from the UI and reports its failure, if any.
    /// Keeps the `do / catch / report` boilerplate out of the views.
    func attempt(_ operation: (NotesViewModel) throws -> Void) {
        do {
            try operation(self)
        } catch {
            report(error)
        }
    }

    // MARK: - Private

    private func save() throws {
        guard modelContext.hasChanges else { return }
        try modelContext.save()
    }
}
