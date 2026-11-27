import Foundation

/// Filters offered by the chips under the home title.
enum NoteFilter: String, CaseIterable, Identifiable {
    case all, pinned, recent

    var id: String { rawValue }

    var title: String {
        switch self {
        // Own keys: "Pinned" alone is also the (singular) state of one note.
        case .all:    return String(localized: "filter.all", defaultValue: "All",
                                    comment: "Filter chip: every note")
        case .pinned: return String(localized: "filter.pinned", defaultValue: "Pinned",
                                    comment: "Filter chip: pinned notes (plural)")
        case .recent: return String(localized: "filter.recent", defaultValue: "Recent",
                                    comment: "Filter chip: notes edited recently (plural)")
        }
    }

    /// Window of the "Recent" filter: notes edited during the last seven days.
    static let recentInterval: TimeInterval = 7 * 24 * 3_600

    func includes(_ note: Note, now: Date = .now) -> Bool {
        switch self {
        case .all:    return true
        case .pinned: return note.isPinned
        case .recent: return note.modifiedAt >= now.addingTimeInterval(-Self.recentInterval)
        }
    }

    func apply(to notes: [Note], now: Date = .now) -> [Note] {
        notes.filter { includes($0, now: now) }
    }
}
