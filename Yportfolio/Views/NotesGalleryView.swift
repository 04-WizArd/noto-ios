import SwiftUI
import SwiftData

/// Gallery presentation: the home header, then colour cards in an editorial
/// rhythm (two tall cards, one wide card) under an optional section label.
struct NotesGalleryView<Header: View>: View {
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var tallHeight: CGFloat = 212

    /// Comfortable composition width on large screens (landscape, iPad).
    private let maxContentWidth: CGFloat = 760

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                header
                    .padding(.top, DS.Spacing.xs)
                    .padding(.bottom, DS.Spacing.sm)

                if let label, !notes.isEmpty {
                    SectionLabel(title: label, count: notes.count)
                        .padding(.leading, 4)
                }

                RhythmLayout(tallHeight: tallHeight, singleColumn: dynamicTypeSize.isAccessibilitySize) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                        card(note, slot: RhythmLayout.slot(at: index, count: notes.count,
                                                           singleColumn: dynamicTypeSize.isAccessibilitySize))
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.bottom, DS.Spacing.xl)
            .frame(maxWidth: maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .animation(DS.Motion.standard(reduceMotion), value: notes.map(\.id))
    }

    // MARK: Card

    private func card(_ note: Note, slot: RhythmLayout.Slot) -> some View {
        NoteTile(note: note, isSelecting: isSelecting, selection: $selection, zoomNamespace: zoomNamespace,
                 onOpen: onOpen, onTogglePin: onTogglePin, onDelete: onDelete) {
            NoteCard(note: note, slot: slot)
        }
        .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
    }
}
