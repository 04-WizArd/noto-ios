import SwiftUI
import Testing
@testable import Yportfolio

@MainActor
@Suite("NoteAccent")
struct NoteAccentTests {

    @Test("Raw value round-trips for every accent", arguments: NoteAccent.allCases)
    func rawValueRoundTrip(accent: NoteAccent) {
        #expect(NoteAccent(rawValue: accent.rawValue) == accent)
    }

    @Test("Each accent maps to the matching SwiftUI colour")
    func colorMapping() {
        let expected: [NoteAccent: Color] = [
            .blue: .blue, .green: .green, .orange: .orange, .indigo: .indigo,
            .pink: .pink, .teal: .teal, .purple: .purple, .mint: .mint,
        ]
        #expect(expected.count == NoteAccent.allCases.count)
        for (accent, color) in expected {
            #expect(accent.color == color)
        }
    }

    @Test("Random accent stays within the palette used for new notes")
    func randomAccent() {
        let allowed: Set<NoteAccent> = [.indigo, .pink, .teal, .purple, .orange, .blue, .mint]
        for _ in 0..<200 {
            #expect(allowed.contains(NoteAccent.random()))
        }
    }

    @Test("Note.accent reads and writes the persisted raw value")
    func noteAccentStorage() throws {
        let f = try NotesFixture()
        let note = f.insertNote(createdAt: .now)

        note.accent = .mint
        #expect(note.accentRawValue == "mint")

        note.accentRawValue = NoteAccent.orange.rawValue
        #expect(note.accent == .orange)
    }

    @Test("Unknown stored value falls back to blue")
    func unknownRawValueFallsBack() throws {
        let f = try NotesFixture()
        let note = f.insertNote(createdAt: .now)

        note.accentRawValue = "not-a-colour"

        #expect(note.accent == .blue)
    }
}

@MainActor
@Suite("Note.hasContent")
struct NoteHasContentTests {

    @Test("Blank title and body → no content",
          arguments: zip(["", "  ", "\n", " \t\n"], ["", "\n\n", "  ", ""]))
    func blank(title: String, body: String) throws {
        let f = try NotesFixture()
        let note = f.insertNote(title: title, body: body, createdAt: .now)
        #expect(!note.hasContent)
    }

    @Test("Any visible character in title or body → content",
          arguments: zip(["a", "", " a ", "\nx"], ["", "b", "", ""]))
    func notBlank(title: String, body: String) throws {
        let f = try NotesFixture()
        let note = f.insertNote(title: title, body: body, createdAt: .now)
        #expect(note.hasContent)
    }
}



@MainActor
@Suite("Note share text")
struct NoteShareTextTests {

    @Test("Title and body are separated by a blank line, trimmed")
    func titleAndBody() {
        #expect(Note(title: "  Courses ", body: "Pain\nLait\n").shareText == "Courses\n\nPain\nLait")
    }

    @Test("Blank parts are omitted")
    func blankParts() {
        #expect(Note(title: "Seul titre", body: "  ").shareText == "Seul titre")
        #expect(Note(title: "", body: "Seul corps").shareText == "Seul corps")
        #expect(Note().shareText.isEmpty)
    }
}
