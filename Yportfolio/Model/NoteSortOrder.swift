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
}
