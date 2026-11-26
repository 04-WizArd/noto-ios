import Foundation
import Testing
@testable import Yportfolio

@MainActor
@Suite("NoteFilter")
struct NoteFilterTests {

    private let day: TimeInterval = 86_400
    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("All keeps every note, in order")
    func allKeepsEverything() throws {
        let f = try NotesFixture()
        let notes = ["A", "B", "C"].map { f.insertNote(title: $0, createdAt: now) }

        #expect(NoteFilter.all.apply(to: notes, now: now).map(\.title) == ["A", "B", "C"])
    }

    @Test("Pinned keeps only pinned notes")
    func pinnedKeepsPinned() throws {
        let f = try NotesFixture()
        let notes = [
            f.insertNote(title: "A", isPinned: true, createdAt: now),
            f.insertNote(title: "B", createdAt: now),
            f.insertNote(title: "C", isPinned: true, createdAt: now),
        ]

        #expect(NoteFilter.pinned.apply(to: notes, now: now).map(\.title) == ["A", "C"])
    }

    @Test("Recent keeps notes modified during the last seven days (boundary included)")
    func recentUsesModificationDate() throws {
        let f = try NotesFixture()
        let old = now.addingTimeInterval(-30 * day)
        let notes = [
            f.insertNote(title: "today", createdAt: old, modifiedAt: now),
            f.insertNote(title: "boundary", createdAt: old, modifiedAt: now.addingTimeInterval(-7 * day)),
            f.insertNote(title: "stale", createdAt: old, modifiedAt: now.addingTimeInterval(-7 * day - 1)),
            f.insertNote(title: "created-recently-not-edited", createdAt: now.addingTimeInterval(-8 * day)),
        ]

        #expect(NoteFilter.recent.apply(to: notes, now: now).map(\.title) == ["today", "boundary"])
    }
}
