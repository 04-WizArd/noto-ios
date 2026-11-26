import Foundation
import Testing
@testable import Yportfolio

@MainActor
@Suite("NoteSortOrder")
struct NoteSortOrderTests {

    private let day: TimeInterval = 86_400
    private let base = Date(timeIntervalSinceReferenceDate: 800_000_000)

    @Test("Title: localized ascending, case and accent insensitive in order")
    func sortByTitle() throws {
        let f = try NotesFixture()
        let notes = ["Charlie", "alpha", "Écho", "Bravo"].map {
            f.insertNote(title: $0, createdAt: base)
        }

        #expect(NoteSortOrder.title.sorted(notes).map(\.title) == ["alpha", "Bravo", "Charlie", "Écho"])
    }

    @Test("Creation date: newest first, independent of modification date")
    func sortByCreationDate() throws {
        let f = try NotesFixture()
        // created: A oldest … C newest ; modified: A most recent
        let notes = [
            f.insertNote(title: "B", createdAt: base.addingTimeInterval(1 * day), modifiedAt: base.addingTimeInterval(4 * day)),
            f.insertNote(title: "A", createdAt: base, modifiedAt: base.addingTimeInterval(9 * day)),
            f.insertNote(title: "C", createdAt: base.addingTimeInterval(2 * day), modifiedAt: base.addingTimeInterval(3 * day)),
        ]

        #expect(NoteSortOrder.dateCreated.sorted(notes).map(\.title) == ["C", "B", "A"])
    }

    @Test("Modification date: most recently edited first")
    func sortByModificationDate() throws {
        let f = try NotesFixture()
        let notes = [
            f.insertNote(title: "B", createdAt: base.addingTimeInterval(1 * day), modifiedAt: base.addingTimeInterval(4 * day)),
            f.insertNote(title: "A", createdAt: base, modifiedAt: base.addingTimeInterval(9 * day)),
            f.insertNote(title: "C", createdAt: base.addingTimeInterval(2 * day), modifiedAt: base.addingTimeInterval(3 * day)),
        ]

        #expect(NoteSortOrder.dateModified.sorted(notes).map(\.title) == ["A", "B", "C"])
    }

    @Test("An edit through the view model moves the note to the top of the modification sort")
    func editReordersModificationSort() throws {
        let f = try NotesFixture()
        let first = f.viewModel.createNote()
        first.title = "Première"
        f.clock.advance(by: 60)
        let second = f.viewModel.createNote()
        second.title = "Seconde"
        #expect(NoteSortOrder.dateModified.sorted([first, second]).map(\.title) == ["Seconde", "Première"])

        f.clock.advance(by: 60)
        first.body = "Modifiée"
        f.viewModel.noteDidChange(first)

        #expect(NoteSortOrder.dateModified.sorted([first, second]).map(\.title) == ["Première", "Seconde"])
        #expect(NoteSortOrder.dateCreated.sorted([first, second]).map(\.title) == ["Seconde", "Première"])
    }

    // MARK: - Pinned grouping

    /// Two pinned and two unpinned notes whose dates and titles disagree, so each
    /// order gives a different result. "Bravo" (unpinned) is the most recently
    /// modified note overall, yet must stay after the pinned ones.
    private func mixedNotes(_ f: NotesFixture) -> [Note] {
        [
            f.insertNote(title: "Delta", isPinned: true,
                         createdAt: base, modifiedAt: base.addingTimeInterval(5 * day)),
            f.insertNote(title: "Charlie",
                         createdAt: base.addingTimeInterval(2.5 * day), modifiedAt: base.addingTimeInterval(4 * day)),
            f.insertNote(title: "Alpha", isPinned: true,
                         createdAt: base.addingTimeInterval(3 * day), modifiedAt: base.addingTimeInterval(1 * day)),
            f.insertNote(title: "Bravo",
                         createdAt: base.addingTimeInterval(2 * day), modifiedAt: base.addingTimeInterval(6 * day)),
        ]
    }

    @Test("Pinned notes come before the others", arguments: NoteSortOrder.allCases)
    func pinnedFirst(order: NoteSortOrder) throws {
        let f = try NotesFixture()

        let groups = order.grouped(mixedNotes(f))

        #expect(groups.pinned.map(\.title).sorted() == ["Alpha", "Delta"])
        #expect(groups.pinned.allSatisfy { $0.isPinned })
        #expect(groups.others.map(\.title).sorted() == ["Bravo", "Charlie"])
        #expect(groups.others.allSatisfy { !$0.isPinned })
    }

    @Test("The selected order still applies inside each group",
          arguments: zip(
            [NoteSortOrder.dateModified, .dateCreated, .title],
            [
                (pinned: ["Delta", "Alpha"], others: ["Bravo", "Charlie"]),   // modified ↓
                (pinned: ["Alpha", "Delta"], others: ["Charlie", "Bravo"]),   // created ↓
                (pinned: ["Alpha", "Delta"], others: ["Bravo", "Charlie"]),   // title ↑
            ]
          ))
    func orderInsideGroups(order: NoteSortOrder, expected: (pinned: [String], others: [String])) throws {
        let f = try NotesFixture()

        let groups = order.grouped(mixedNotes(f))

        #expect(groups.pinned.map(\.title) == expected.pinned)
        #expect(groups.others.map(\.title) == expected.others)
    }

    @Test("Without pinned notes, grouping is the plain sort", arguments: NoteSortOrder.allCases)
    func noPinnedNotes(order: NoteSortOrder) throws {
        let f = try NotesFixture()
        let notes = mixedNotes(f)
        notes.forEach { $0.isPinned = false }

        let groups = order.grouped(notes)

        #expect(groups.pinned.isEmpty)
        #expect(groups.others.map(\.title) == order.sorted(notes).map(\.title))
    }

    @Test("Sorting never drops or duplicates notes", arguments: NoteSortOrder.allCases)
    func sortKeepsAllNotes(order: NoteSortOrder) throws {
        let f = try NotesFixture()
        let notes = (0..<5).map { f.insertNote(title: "N\($0)", createdAt: base.addingTimeInterval(Double($0))) }

        let sorted = order.sorted(notes)

        #expect(sorted.count == notes.count)
        #expect(Set(sorted.map(\.title)) == Set(notes.map(\.title)))
    }
}
