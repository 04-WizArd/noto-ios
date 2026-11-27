import SwiftUI
import SwiftData

/// List presentation: the home header, then full-width note cards under an
/// optional section label. Native `List` for swipe actions and cell reuse.
struct NotesListView<Header: View>: View {
    let notes: [Note]
    var label: String? = nil
    let isSelecting: Bool
    @Binding var selection: Set<Note.ID>
    let zoomNamespace: Namespace.ID
    let onOpen: (Note) -> Void
    let onTogglePin: (Note) -> Void
    let onDelete: (Note) -> Void
    @ViewBuilder let header: Header

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        List {
            header
                .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.screen,
                                          bottom: DS.Spacing.lg, trailing: DS.Spacing.screen))
                .plainListRow()

            Section {
                if let label, !notes.isEmpty {
                    sectionLabel(SectionLabel(title: label, count: notes.count))
                }
                ForEach(notes, content: row)
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, DS.Spacing.lg, for: .scrollContent)
    }

    private func sectionLabel(_ label: SectionLabel) -> some View {
        label
            .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.screen + 4,
                                      bottom: DS.Spacing.xs, trailing: DS.Spacing.screen))
            .plainListRow()
    }

    private func row(_ note: Note) -> some View {
        let isSelected = isSelecting && selection.contains(note.id)
        return Button {
            if isSelecting {
                withAnimation(DS.Motion.quick(reduceMotion)) { selection.toggle(note.id) }
            } else {
                onOpen(note)
            }
        } label: {
            NoteRowView(note: note, isSelected: isSelected)
                .matchedTransitionSource(id: note.zoomID, in: zoomNamespace) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: DS.Radius.row, style: .continuous))
                }
        }
        .buttonStyle(.card)
        .overlay(alignment: .topTrailing) {
            cornerControl(for: note, isSelected: isSelected)
                .padding(4)
        }
        .listRowInsets(EdgeInsets(top: 5, leading: DS.Spacing.screen, bottom: 5, trailing: DS.Spacing.screen))
        .plainListRow()
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isSelecting {
                Button {
                    onTogglePin(note)
                } label: {
                    Label(note.isPinned ? String(localized: "Unpin") : String(localized: "Pin"),
                          systemImage: note.isPinned ? "bookmark.slash.fill" : "bookmark.fill")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isSelecting {
                Button(role: .destructive) {
                    onDelete(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityValue(note.isPinned ? String(localized: "Pinned") : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func cornerControl(for note: Note, isSelected: Bool) -> some View {
        if isSelecting {
            SelectionIndicator(isSelected: isSelected)
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
        } else {
            PinToggle(isPinned: note.isPinned) { onTogglePin(note) }
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
        }
    }
}

// MARK: - Shared helpers

extension View {
    /// A list row without separator or background (the content draws its own card).
    func plainListRow() -> some View {
        listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) { remove(element) } else { insert(element) }
    }
}
