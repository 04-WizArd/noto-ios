import Foundation

/// Layout used to display the notes collection.
enum NoteViewStyle {
    case list, gallery

    var toggled: NoteViewStyle { self == .list ? .gallery : .list }

    /// Label / icon of the button that switches *to the other* style.
    var switchLabel: String { self == .list ? "Vue galerie" : "Vue liste" }
    var switchIcon: String { self == .list ? "square.grid.2x2" : "list.bullet" }
}
