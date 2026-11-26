import SwiftUI
import SwiftData

/// List presentation: the home header, then full-width note cards in two groups
/// ("Épinglées", "Notes"). Native `List` for swipe actions and cell reuse.
struct NotesListView<Header: View>: View {
    let pinned: [Note]
    let others: [Note]
    let isSelecting: Bool
    @Binding var selection: Set<Note.ID>
    @Binding var isHeaderCollapsed: Bool
    let zoomNamespace: Namespace.ID
    let onOpen: (Note) -> Void
    let onTogglePin: (Note) -> Void
    let onDelete: (Note) -> Void
    @ViewBuilder let header: Header

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasPinned: Bool { !pinned.isEmpty }

    var body: some View {
        List {
            header
                .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.screen,
                                          bottom: DS.Spacing.lg, trailing: DS.Spacing.screen))
                .plainListRow()

            // Both sections always exist (labels only when something is pinned), so a
            // note moving in or out of "Épinglées" keeps its identity and animates as a move.
            Section {
                if hasPinned {
                    label(SectionLabel(title: "Épinglées", systemImage: "pin.fill", count: pinned.count))
                }
                ForEach(pinned, content: row)
            }
            Section {
                if hasPinned && !others.isEmpty {
                    label(SectionLabel(title: "Notes", count: others.count))
                }
                ForEach(others, content: row)
            }
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .contentMargins(.bottom, DS.Spacing.lg, for: .scrollContent)
        .tracksHeaderCollapse($isHeaderCollapsed)
    }

    private func label(_ label: SectionLabel) -> some View {
        label
            .listRowInsets(EdgeInsets(top: DS.Spacing.md, leading: DS.Spacing.screen + 4,
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
                    Label(note.isPinned ? "Désépingler" : "Épingler",
                          systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isSelecting {
                Button(role: .destructive) {
                    onDelete(note)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
        .accessibilityValue(note.isPinned ? "Épinglée" : "")
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

    /// Reports whether the home header (display title) has scrolled under the top bar.
    func tracksHeaderCollapse(_ isCollapsed: Binding<Bool>) -> some View {
        onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > 56
        } action: { _, collapsed in
            isCollapsed.wrappedValue = collapsed
        }
    }
}

extension Set {
    mutating func toggle(_ element: Element) {
        if contains(element) { remove(element) } else { insert(element) }
    }
}
