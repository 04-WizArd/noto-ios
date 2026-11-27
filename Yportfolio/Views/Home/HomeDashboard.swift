import SwiftUI
import SwiftData

/// Home "featured deck": the first notes of the current filter and sort, as a
/// numbered stack of cards seen from above.
///
/// - The front card shows the priority note in full: its large rank numeral in the
///   note's accent, title, preview and relative date.
/// - The other notes sit behind it, each one a little narrower, and show only their
///   bottom strip (rank, title, bookmark) tinted with their accent.
/// - Reading top to bottom follows the priority order (01, 02, 03).
///
/// Tapping the front card opens the note (zoom transition); tapping a strip brings
/// that note to the front. Cards fan out from behind the front card when the deck
/// appears; with Reduce Motion everything is simply in place.
struct HomeDashboard: View {
    /// One to three notes, in priority order.
    let notes: [Note]
    /// `false` when the dashboard is hosted in a `List` row (see `NoteTile.showsContextMenu`).
    var showsContextMenus = true
    let isSelecting: Bool
    @Binding var selection: Set<Note.ID>
    let zoomNamespace: Namespace.ID
    let onOpen: (Note) -> Void
    let onTogglePin: (Note) -> Void
    let onDelete: (Note) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 212
    @ScaledMetric(relativeTo: .headline) private var stripHeight: CGFloat = 54

    /// Note brought to the front by the user (view state only; reset when the
    /// featured notes or their order change).
    @State private var frontID: Note.ID?
    /// Cards start gathered behind the front card, then fan out once.
    @State private var isFannedOut = false

    static let maxCount = 3
    /// Width lost by each card on each side, per level of depth.
    private let depthInset: CGFloat = 14
    /// How far a back card slips under the card in front of it: enough to fill
    /// the rounded corners above its strip, so the stack reads as continuous.
    private let tuck: CGFloat = DS.Radius.card

    /// Display order: the chosen front note first, then the others by priority.
    private var deck: [Note] {
        guard let frontID, let index = notes.firstIndex(where: { $0.id == frontID }) else { return notes }
        var rest = notes
        let front = rest.remove(at: index)
        return [front] + rest
    }

    private var motion: Animation? {
        reduceMotion ? nil : .spring(duration: 0.5, bounce: 0.16)
    }

    var body: some View {
        let deck = deck
        ZStack(alignment: .top) {
            // Back cards first: the front card is drawn last, on top.
            ForEach(Array(deck.enumerated().reversed()), id: \.element.id) { depth, note in
                card(note, depth: depth)
                    .zIndex(Double(deck.count - depth))
            }
        }
        .frame(height: cardHeight + CGFloat(deck.count - 1) * stripHeight, alignment: .top)
        .animation(motion, value: deck.map(\.id))
        .onChange(of: notes.map(\.id)) { _, _ in frontID = nil }
        .onAppear(perform: fanOut)
    }

    // MARK: Card

    /// Back cards are only as tall as what shows of them (strip + tuck), so their
    /// touch and accessibility frames match the visible strip; bringing one to the
    /// front animates its height from the strip to the full card.
    private func card(_ note: Note, depth: Int) -> some View {
        let isFront = depth == 0
        // Gathered: every back card hides exactly behind the front card's bottom edge.
        let level = CGFloat(isFannedOut ? depth : 0)
        let height = isFront ? cardHeight : stripHeight + tuck
        let y = isFront ? 0 : cardHeight - tuck + (level - 1) * stripHeight
        let rank = (notes.firstIndex { $0.id == note.id } ?? depth) + 1
        return NoteTile(
            note: note,
            showsContextMenu: showsContextMenus,
            controlAlignment: isFront ? .topTrailing : .bottomTrailing,
            accessibilityOpen: isFront ? nil : { onOpen(note) },
            isSelecting: isSelecting, selection: $selection, zoomNamespace: zoomNamespace,
            onOpen: isFront ? onOpen : bringToFront,
            onTogglePin: onTogglePin, onDelete: onDelete
        ) {
            DeckCard(note: note, rank: rank, isFront: isFront, stripHeight: stripHeight)
        }
        .frame(height: height)
        .padding(.horizontal, CGFloat(depth) * depthInset)
        .offset(y: y)
        .accessibilityHint(isFront ? "" : String(localized: "Brings this note to the front."))
    }

    // MARK: Motion

    private func bringToFront(_ note: Note) {
        withAnimation(motion) { frontID = note.id }
    }

    private func fanOut() {
        guard !isFannedOut else { return }
        if reduceMotion {
            isFannedOut = true
        } else {
            withAnimation(.spring(duration: 0.6, bounce: 0.14).delay(0.12)) { isFannedOut = true }
        }
    }
}

// MARK: - Deck card

/// One card of the deck. In front: the full note. Behind: only its bottom strip
/// is visible, so that is all it draws.
struct DeckCard: View {
    let note: Note
    let rank: Int
    let isFront: Bool
    let stripHeight: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
    }

    /// "01", "02", "03": the deck's signature, set in the note's accent.
    private var rankLabel: String { String(format: "%02d", rank) }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isFront {
                front.transition(.opacity)
            } else {
                strip.transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background { surface }
        .clipShape(shape)
        .overlay {
            // Dark Mode: a hairline edge separates the stacked cards.
            shape.strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.09 : 0), lineWidth: 1)
        }
        // Light Mode: each card casts a soft shadow onto the one behind it.
        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.08), radius: 12, y: 6)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }

    /// Opaque surfaces (cards overlap): neutral in front, the note's tint behind.
    @ViewBuilder
    private var surface: some View {
        if isFront {
            DS.Surface.raised
        } else {
            ZStack {
                DS.Surface.background
                DS.Surface.tint(note.accent.color, colorScheme)
            }
        }
    }

    private var front: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(rankLabel)
                .font(.system(size: 34, weight: .heavy, design: .monospaced))
                .foregroundStyle(note.accent.color)
                .accessibilityHidden(true)

            Spacer(minLength: DS.Spacing.sm)

            Text(note.displayTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            if !note.bodyPreview.isEmpty {
                Text(note.bodyPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, DS.Spacing.xxs)
            }

            // Locale-aware: "il y a 6 heures", "hier" / "6 hours ago", "yesterday".
            Text(note.modifiedAt, format: .relative(presentation: .named, unitsStyle: .wide))
                .font(DS.Typography.metadata)
                .foregroundStyle(.secondary)
                .padding(.top, DS.Spacing.sm)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var strip: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text(rankLabel)
                .font(.system(size: 15, weight: .heavy, design: .monospaced))
                .foregroundStyle(note.accent.color.mix(with: .primary, by: 0.25))
                .accessibilityHidden(true)
            Text(note.displayTitle)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
            // Room for the bookmark control in the strip's trailing corner.
            Spacer(minLength: 44)
        }
        .padding(.horizontal, 18)
        .frame(height: stripHeight)
    }
}

// MARK: - Previews

#Preview(traits: .sampleNotes) {
    @Previewable @Query(sort: \Note.modifiedAt, order: .reverse) var notes: [Note]
    @Previewable @Namespace var ns
    @Previewable @State var selection = Set<Note.ID>()
    VStack(spacing: 40) {
        HomeDashboard(notes: Array(notes.prefix(3)), isSelecting: false, selection: $selection,
                      zoomNamespace: ns, onOpen: { _ in }, onTogglePin: { _ in }, onDelete: { _ in })
        HomeDashboard(notes: Array(notes.prefix(1)), isSelecting: false, selection: $selection,
                      zoomNamespace: ns, onOpen: { _ in }, onTogglePin: { _ in }, onDelete: { _ in })
    }
    .padding()
}
