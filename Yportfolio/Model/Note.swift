import Foundation
import SwiftData

@Model
final class Note {
    var title: String = ""
    var body: String = ""
    /// Set once at creation, never changed afterwards.
    var createdAt: Date = Date.now
    /// Updated whenever the title or body is edited.
    var modifiedAt: Date = Date.now
    var isPinned: Bool = false
    /// Raw storage for `accent` — use `accent` instead.
    var accentRawValue: String = NoteAccent.blue.rawValue

    init(
        title: String = "",
        body: String = "",
        accent: NoteAccent = .blue,
        isPinned: Bool = false,
        createdAt: Date = .now,
        modifiedAt: Date? = nil
    ) {
        self.title = title
        self.body = body
        self.accentRawValue = accent.rawValue
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt ?? createdAt
    }
}

extension Note {
    var accent: NoteAccent {
        get { NoteAccent(rawValue: accentRawValue) ?? .blue }
        set { accentRawValue = newValue.rawValue }
    }

    /// `false` when both title and body are blank (whitespace only).
    var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
