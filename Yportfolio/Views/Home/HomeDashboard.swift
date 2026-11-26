import SwiftUI
import SwiftData

/// Home dashboard: the first notes of the current filter and sort, composed like
/// a widget stack — one tall featured card on the left, a visual card and a
/// compact card stacked on the right. At accessibility text sizes the cards
/// stack in one column at their natural height.
struct HomeDashboard: View {
    /// One to three notes, in display order.
    let notes: [Note]
    /// `false` when the dashboard is hosted in a `List` row (see `NoteTile.showsContextMenu`).
    var showsContextMenus = true
    let isSelecting: Bool
    @Binding var selection: Set<Note.ID>
    let zoomNamespace: Namespace.ID
    let onOpen: (Note) -> Void
    let onTogglePin: (Note) -> Void
    let onDelete: (Note) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 322
    @ScaledMetric(relativeTo: .body) private var compactHeight: CGFloat = 132

    static let maxCount = 3
    private let gap: CGFloat = 12

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: gap) {
                ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                    tile(note, style: Style(index))
                        .frame(minHeight: index == 1 ? 180 : nil)
                }
            }
        } else {
            HStack(spacing: gap) {
                if let first = notes.first {
                    tile(first, style: .featured)
                }
                if notes.count > 1 {
                    VStack(spacing: gap) {
                        tile(notes[1], style: .visual)
                        if notes.count > 2 {
                            tile(notes[2], style: .compact)
                                .frame(height: compactHeight)
                        }
                    }
                }
            }
            .frame(height: notes.count == 1 ? height * 0.75 : height)
        }
    }

    // MARK: Tiles

    enum Style {
        case featured, visual, compact

        init(_ index: Int) {
            self = [.featured, .visual, .compact][min(index, 2)]
        }
    }

    private func tile(_ note: Note, style: Style) -> some View {
        NoteTile(note: note, cornerRadius: DS.Radius.hero, showsContextMenu: showsContextMenus,
                 isSelecting: isSelecting, selection: $selection, zoomNamespace: zoomNamespace,
                 onOpen: onOpen, onTogglePin: onTogglePin, onDelete: onDelete) {
            switch style {
            case .featured: FeaturedNoteCard(note: note)
            case .visual:   VisualNoteCard(note: note)
            case .compact:  CompactNoteCard(note: note)
            }
        }
    }
}

// MARK: - Featured card

/// Tall card: the title set large in a monospaced heavy face, centred, with the
/// note's first lines as pills underneath (the first one highlighted).
struct FeaturedNoteCard: View {
    let note: Note

    @ScaledMetric(relativeTo: .title) private var titleSize: CGFloat = 26

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.hero, style: .continuous)
    }

    var body: some View {
        let lines = note.highlights()
        VStack(spacing: 0) {
            Spacer(minLength: 36)   // keeps the title clear of the pin control

            Text(note.displayTitle.uppercased())
                .font(.system(size: titleSize, weight: .heavy, design: .monospaced))
                .tracking(1)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DS.Spacing.xs)
                .accessibilityLabel(note.displayTitle)

            Spacer(minLength: DS.Spacing.md)

            VStack(spacing: DS.Spacing.xs) {
                if lines.isEmpty {
                    LinePill(text: note.shortModifiedDate, systemImage: "clock", accent: note.accent.color)
                } else {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        LinePill(text: line, number: index + 1, highlighted: index == 0,
                                 accent: note.accent.color)
                    }
                }
            }
        }
        .padding(DS.Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Surface.raised, in: shape)
        .accessibilityElement(children: .combine)
    }
}

/// One line of the featured card: a capsule with a numbered disc and the text.
struct LinePill: View {
    let text: String
    var number: Int? = nil
    var systemImage: String? = nil
    var highlighted = false
    let accent: Color

    @ScaledMetric(relativeTo: .subheadline) private var discSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                if highlighted {
                    Circle().fill(accent.opacity(0.22))
                } else {
                    Circle().strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1.2)
                }
                Group {
                    if let number {
                        Text(number, format: .number)
                    } else if let systemImage {
                        Image(systemName: systemImage)
                    }
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(highlighted ? accent : Color.secondary)
            }
            .frame(width: discSize, height: discSize)
            .accessibilityHidden(true)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(minHeight: 44)
        .background(DS.Surface.inset.opacity(highlighted ? 1 : 0.65), in: Capsule())
        .overlay {
            Capsule().strokeBorder(DS.Surface.hairline, lineWidth: 1)
                .opacity(highlighted ? 1 : 0)
        }
    }
}

// MARK: - Visual card

/// Image-like card: a soft mesh of the note's colours (standing in for a picture),
/// with the title and a relative date over a gentle shade.
struct VisualNoteCard: View {
    let note: Note

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            NoteMesh(accent: note.accent, scheme: colorScheme)

            LinearGradient(colors: [.clear, .black.opacity(0.38)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 3) {
                Text(note.displayTitle)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
                Text(note.modifiedAt, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                    .font(.subheadline)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.2), radius: 6, y: 1)
            .padding(18)
            .padding(.trailing, DS.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.hero, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Blurred, iridescent wash built from a note's accent and a companion hue.
struct NoteMesh: View {
    let accent: NoteAccent
    let scheme: ColorScheme

    var body: some View {
        let a = accent.color
        let b = accent.companion.color
        let depth: CGFloat = scheme == .dark ? 0.55 : 0.35
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.62, 0.4], [1, 0.55],
                [0, 1], [0.45, 1], [1, 1],
            ],
            colors: [
                a.mix(with: .white, by: 0.45), b.mix(with: .white, by: 0.2), a.mix(with: .black, by: depth * 0.6),
                b.mix(with: .white, by: 0.55), .white.mix(with: a, by: 0.25), a,
                a.mix(with: .black, by: depth), b.mix(with: .black, by: depth * 0.8), a.mix(with: .black, by: depth + 0.1),
            ],
            smoothsColors: true
        )
    }
}

private extension NoteAccent {
    /// Second hue of the mesh, chosen to sit next to the accent on the colour wheel.
    var companion: NoteAccent {
        switch self {
        case .blue:   return .purple
        case .green:  return .teal
        case .orange: return .pink
        case .indigo: return .pink
        case .pink:   return .orange
        case .teal:   return .blue
        case .purple: return .indigo
        case .mint:   return .blue
        }
    }
}

// MARK: - Compact card

/// Small card: two sheets of paper fanned out (the note as a document), and the
/// title beside a document badge.
struct CompactNoteCard: View {
    let note: Note

    @ScaledMetric(relativeTo: .subheadline) private var badgeSize: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaperStack(accent: note.accent.color)
                .frame(maxWidth: .infinity, minHeight: 50, maxHeight: .infinity)
                .padding(.top, DS.Spacing.xxs)

            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(DS.Surface.inset, in: Circle())
                    .overlay { Circle().strokeBorder(DS.Surface.hairline, lineWidth: 1) }
                    .accessibilityHidden(true)

                Text(note.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(DS.Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Surface.raised, in: RoundedRectangle(cornerRadius: DS.Radius.hero, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Two fanned sheets: a coloured one behind, a white one with text lines in front.
private struct PaperStack: View {
    let accent: Color

    var body: some View {
        ZStack {
            sheet(fill: accent, lines: .white.opacity(0.75))
                .rotationEffect(.degrees(-12))
                .offset(x: -11, y: 2)
            sheet(fill: DS.Surface.inset, lines: Color.secondary.opacity(0.45))
                .rotationEffect(.degrees(9))
                .offset(x: 11)
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .accessibilityHidden(true)
    }

    private func sheet(fill: some ShapeStyle, lines: Color) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(fill)
            .frame(width: 34, height: 44)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array([20.0, 16, 20, 12].enumerated()), id: \.offset) { _, width in
                        Capsule().fill(lines).frame(width: width, height: 2.5)
                    }
                }
                .padding(7)
            }
    }
}

// MARK: - Previews

#Preview(traits: .sampleNotes) {
    @Previewable @Query(sort: \Note.modifiedAt, order: .reverse) var notes: [Note]
    @Previewable @Namespace var ns
    @Previewable @State var selection = Set<Note.ID>()
    HomeDashboard(notes: Array(notes.prefix(3)), isSelecting: false, selection: $selection,
                  zoomNamespace: ns, onOpen: { _ in }, onTogglePin: { _ in }, onDelete: { _ in })
        .padding()
}
