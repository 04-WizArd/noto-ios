import Foundation

/// Sort options offered in the notes list menu.
enum NoteSortOrder: String, CaseIterable, Identifiable {
    case dateModified = "dateModified"
    case dateCreated  = "dateCreated"
    case title        = "title"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateModified: return "Date de modification"
        case .dateCreated:  return "Date de création"
        case .title:        return "Titre"
        }
    }

    var icon: String {
        switch self {
        case .dateModified: return "clock.arrow.circlepath"
        case .dateCreated:  return "calendar"
        case .title:        return "textformat.abc"
        }
    }

    /// Dates: newest first. Title: localized ascending.
    func sorted(_ notes: [Note]) -> [Note] {
        switch self {
        case .dateModified:
            return notes.sorted { $0.modifiedAt > $1.modifiedAt }
        case .dateCreated:
            return notes.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return notes.sorted {
                $0.title.localizedCompare($1.title) == .orderedAscending
            }
        }
    }

    /// Splits notes into pinned and other notes, each group sorted by this order.
    /// Pinned notes are always displayed first.
    func grouped(_ notes: [Note]) -> (pinned: [Note], others: [Note]) {
        let ordered = sorted(notes)
        return (ordered.filter(\.isPinned), ordered.filter { !$0.isPinned })
    }
}
