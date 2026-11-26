import Foundation
import SwiftData
import Testing
@testable import Yportfolio

@MainActor
@Suite("NotesViewModel")
struct NotesViewModelTests {

    // MARK: - Create

    @Test("Creating a note inserts an empty note stamped with the current date")
    func createNote() throws {
        let f = try NotesFixture()

        let note = f.viewModel.createNote(accent: .teal)

        #expect(note.title.isEmpty)
        #expect(note.body.isEmpty)
        #expect(note.createdAt == f.clock.now)
        #expect(note.modifiedAt == f.clock.now)
        #expect(note.isPinned == false)
        #expect(note.accent == .teal)
        #expect(try f.context.fetch(FetchDescriptor<Note>()).count == 1)
    }

    @Test("All properties are persisted to the store")
    func propertiesArePersisted() throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote(accent: .purple)
        let createdAt = note.createdAt

        f.clock.advance(by: 60)
        note.title = "Titre"
        note.body = "Corps\nligne 2"
        note.isPinned = true
        f.viewModel.noteDidChange(note)
        try f.viewModel.finishEditing(note)

        let saved = try #require(try f.fetchSavedNotes().first)
        #expect(saved.title == "Titre")
        #expect(saved.body == "Corps\nligne 2")
        #expect(saved.isPinned == true)
        #expect(saved.accent == .purple)
        #expect(saved.accentRawValue == "purple")
        #expect(saved.createdAt == createdAt)
        #expect(saved.modifiedAt == f.clock.now)
    }

    // MARK: - Dates

    @Test("createdAt never changes when the note is edited")
    func createdAtIsStable() throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote()
        let createdAt = note.createdAt

        for text in ["A", "AB", "ABC"] {
            f.clock.advance(by: 30)
            note.title = text
            f.viewModel.noteDidChange(note)
        }
        try f.viewModel.finishEditing(note)

        #expect(note.createdAt == createdAt)
        #expect(try f.fetchSavedNotes().first?.createdAt == createdAt)
    }

    @Test("modifiedAt moves forward on every edit")
    func modifiedAtAdvances() throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote()
        let initial = note.modifiedAt

        f.clock.advance(by: 120)
        note.body = "Nouveau texte"
        f.viewModel.noteDidChange(note)

        #expect(note.modifiedAt == f.clock.now)
        #expect(note.modifiedAt > initial)
        #expect(note.modifiedAt > note.createdAt)
    }

    // MARK: - Pin

    @Test("Pinning a note sets isPinned and saves it")
    func pinNote() throws {
        let f = try NotesFixture()
        let note = try f.savedNote("À épingler")

        try f.viewModel.togglePin(note)

        #expect(note.isPinned)
        #expect(try f.fetchSavedNotes().first?.isPinned == true)
    }

    @Test("Unpinning a pinned note clears isPinned and saves it")
    func unpinNote() throws {
        let f = try NotesFixture()
        let note = try f.savedNote("Épinglée")
        try f.viewModel.togglePin(note)

        try f.viewModel.togglePin(note)

        #expect(!note.isPinned)
        #expect(try f.fetchSavedNotes().first?.isPinned == false)
    }

    @Test("Pinning and unpinning never change modifiedAt or createdAt")
    func pinKeepsDates() throws {
        let f = try NotesFixture()
        let note = try f.savedNote("Dates")
        let createdAt = note.createdAt
        let modifiedAt = note.modifiedAt

        f.clock.advance(by: 3_600)
        try f.viewModel.togglePin(note)
        f.clock.advance(by: 3_600)
        try f.viewModel.togglePin(note)
        try f.viewModel.togglePin(note)

        let saved = try #require(try f.fetchSavedNotes().first)
        #expect(saved.isPinned)
        #expect(saved.createdAt == createdAt)
        #expect(saved.modifiedAt == modifiedAt)
    }

    @Test("Toggling pins never loses or duplicates notes")
    func pinTogglingKeepsAllNotes() throws {
        let f = try NotesFixture()
        let titles = (0..<6).map { "Note \($0)" }
        let notes = try titles.map { try f.savedNote($0) }

        for index in [0, 2, 4, 2, 5, 5] {
            try f.viewModel.togglePin(notes[index])
        }

        let saved = try f.fetchSavedNotes()
        #expect(saved.count == titles.count)
        #expect(Set(saved.map(\.title)) == Set(titles))
        #expect(saved.filter(\.isPinned).map(\.title).sorted() == ["Note 0", "Note 4"])

        for order in NoteSortOrder.allCases {
            let groups = order.grouped(saved)
            let displayed = groups.pinned + groups.others
            #expect(displayed.count == titles.count)
            #expect(Set(displayed.map(\.persistentModelID)).count == titles.count)
        }
    }

    // MARK: - Delete

    @Test("Deleting a note removes it from the store")
    func deleteNote() throws {
        let f = try NotesFixture()
        let kept = f.viewModel.createNote()
        kept.title = "Gardée"
        let deleted = f.viewModel.createNote()
        deleted.title = "Supprimée"
        try f.viewModel.finishEditing(kept)
        try f.viewModel.finishEditing(deleted)

        try f.viewModel.delete(deleted)

        #expect(try f.fetchSavedNotes().map(\.title) == ["Gardée"])
    }

    @Test("Deleting several notes at once removes all of them")
    func deleteSeveralNotes() throws {
        let f = try NotesFixture()
        let notes = (1...3).map { index in
            let note = f.viewModel.createNote()
            note.title = "Note \(index)"
            return note
        }
        try f.viewModel.delete(Array(notes.prefix(2)))

        #expect(try f.fetchSavedNotes().map(\.title) == ["Note 3"])
    }

    @Test("Deleting a multi-selection removes pinned and unpinned notes and keeps the rest")
    func deleteMixedSelection() throws {
        let f = try NotesFixture()
        let pinnedKept = try f.savedNote("Épinglée gardée")
        let pinnedDeleted = try f.savedNote("Épinglée supprimée")
        let deleted = try f.savedNote("Supprimée")
        _ = try f.savedNote("Gardée")
        try f.viewModel.togglePin(pinnedKept)
        try f.viewModel.togglePin(pinnedDeleted)

        try f.viewModel.delete([pinnedDeleted, deleted])

        let saved = try f.fetchSavedNotes()
        #expect(Set(saved.map(\.title)) == ["Épinglée gardée", "Gardée"])
        #expect(saved.first { $0.title == "Épinglée gardée" }?.isPinned == true)
    }

    @Test("Deleting an empty selection changes nothing")
    func deleteEmptySelection() throws {
        let f = try NotesFixture()
        _ = try f.savedNote("Seule")

        try f.viewModel.delete([Note]())

        #expect(try f.fetchSavedNotes().map(\.title) == ["Seule"])
    }

    @Test("Deleting from the editor removes even a note with content")
    func finishEditingWithDeleteRequest() throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote()
        note.title = "À supprimer"

        let deleted = try f.viewModel.finishEditing(note, deleteRequested: true)

        #expect(deleted)
        #expect(try f.fetchSavedNotes().isEmpty)
    }

    // MARK: - Empty-note cleanup

    @Test("A note left completely empty is deleted when the editor closes")
    func emptyNoteIsDeleted() throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote()

        let deleted = try f.viewModel.finishEditing(note)

        #expect(deleted)
        #expect(try f.fetchSavedNotes().isEmpty)
    }

    @Test("A note containing only whitespace / newlines is deleted",
          arguments: ["   ", "\n", "\n\n", " \t\n  "])
    func blankNoteIsDeleted(blank: String) throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote()
        note.title = blank
        note.body = blank

        let deleted = try f.viewModel.finishEditing(note)

        #expect(deleted)
        #expect(try f.fetchSavedNotes().isEmpty)
    }

    @Test("A note with real text is kept",
          arguments: zip(["Titre", "", "  Titre  ", "\n"],
                         ["", "Corps", "\n", "  x  "]))
    func noteWithContentIsKept(title: String, body: String) throws {
        let f = try NotesFixture()
        let note = f.viewModel.createNote()
        note.title = title
        note.body = body

        let deleted = try f.viewModel.finishEditing(note)

        #expect(!deleted)
        let saved = try f.fetchSavedNotes()
        #expect(saved.count == 1)
        #expect(saved.first?.title == title)
        #expect(saved.first?.body == body)
    }

    @Test("Launch cleanup deletes only notes without content")
    func deleteEmptyNotes() throws {
        let f = try NotesFixture()
        let full = f.viewModel.createNote()
        full.body = "Contenu"
        _ = f.viewModel.createNote()                 // empty
        let blank = f.viewModel.createNote()
        blank.title = " \n "                         // whitespace only
        try f.context.save()

        let count = try f.viewModel.deleteEmptyNotes()

        #expect(count == 2)
        #expect(try f.fetchSavedNotes().map(\.body) == ["Contenu"])
    }

    // MARK: - Errors

    @Test("report(_:) exposes the error to the UI")
    func reportStoresLastError() throws {
        struct SampleError: Error {}
        let f = try NotesFixture()
        #expect(f.viewModel.lastError == nil)

        f.viewModel.report(SampleError())

        #expect(f.viewModel.lastError is SampleError)
    }
}
