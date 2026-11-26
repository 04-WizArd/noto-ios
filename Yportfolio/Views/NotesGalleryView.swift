import SwiftUI
import SwiftData

/// Gallery presentation: the home header, then colour cards in an editorial
/// rhythm (two tall cards, one wide card). Pinned notes come first under their label.
struct NotesGalleryView<Header: View>: View {
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var tallHeight: CGFloat = 212

    /// Comfortable composition width on large screens (landscape, iPad).
    private let maxContentWidth: CGFloat = 760

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, DS.Spacing.xs)
                    .padding(.bottom, DS.Spacing.xl)

                if !pinned.isEmpty {
                    section(label: SectionLabel(title: "Épinglées", systemImage: "pin.fill", count: pinned.count),
                            notes: pinned)
                }
                if !others.isEmpty {
                    section(label: pinned.isEmpty ? nil : SectionLabel(title: "Notes", count: others.count),
                            notes: others)
                }
            }
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.bottom, DS.Spacing.lg)
            .frame(maxWidth: maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .tracksHeaderCollapse($isHeaderCollapsed)
        .animation(DS.Motion.standard(reduceMotion), value: pinned.map(\.id))
        .animation(DS.Motion.standard(reduceMotion), value: others.map(\.id))
    }

    // MARK: Section

    private func section(label: SectionLabel?, notes: [Note]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            if let label {
                label.padding(.leading, 4)
            }
            RhythmLayout(tallHeight: tallHeight, singleColumn: dynamicTypeSize.isAccessibilitySize) {
                ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                    card(note, slot: RhythmLayout.slot(at: index, count: notes.count,
                                                       singleColumn: dynamicTypeSize.isAccessibilitySize))
                }
            }
        }
        .padding(.bottom, DS.Spacing.xl)
    }

    // MARK: Card

    private func card(_ note: Note, slot: RhythmLayout.Slot) -> some View {
        let isSelected = isSelecting && selection.contains(note.id)
        return Button {
            if isSelecting {
                withAnimation(DS.Motion.quick(reduceMotion)) { selection.toggle(note.id) }
            } else {
                onOpen(note)
            }
        } label: {
            NoteCard(note: note, slot: slot, isSelected: isSelected)
                .scaleEffect(isSelected && !reduceMotion ? 0.97 : 1)
                .matchedTransitionSource(id: note.zoomID, in: zoomNamespace) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                }
        }
        .buttonStyle(.card)
        .overlay(alignment: .topTrailing) {
            Group {
                if isSelecting {
                    SelectionIndicator(isSelected: isSelected)
                } else {
                    PinToggle(isPinned: note.isPinned) { onTogglePin(note) }
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.7)))
            .padding(6)
        }
        .contextMenu {
            if !isSelecting {
                Button {
                    onTogglePin(note)
                } label: {
                    Label(note.isPinned ? "Désépingler" : "Épingler",
                          systemImage: note.isPinned ? "pin.slash" : "pin")
                }
                Button(role: .destructive) {
                    onDelete(note)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
        }
        .accessibilityActions {
            if !isSelecting {
                Button("Supprimer", role: .destructive) { onDelete(note) }
            }
        }
        .accessibilityValue(note.isPinned ? "Épinglée" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
    }
}
