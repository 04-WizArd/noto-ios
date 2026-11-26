import SwiftUI
import SwiftData

/// Gallery card for a single note.
struct NoteCard: View {
    let note: Note

    @Environment(\.colorScheme) private var scheme

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            cardBackground
            contentStack
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
        .cardShadow(accent: note.accent.color, scheme: scheme)
        .overlay(borderOverlay)
    }

    // MARK: - Subviews

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
            .fill(DS.Material.card)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(note.accent.color.opacity(scheme == .dark ? 0.15 : 0.07))
            )
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
            .strokeBorder(
                Color.white.opacity(scheme == .dark ? 0.10 : 0.50),
                lineWidth: 0.5
            )
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            dateRow
                .padding(.bottom, DS.Spacing.xs + 2)

            titleText
                .padding(.bottom, DS.Spacing.xxs + 2)

            snippetText

            Spacer(minLength: DS.Spacing.sm)

            footerBadge
        }
        .padding(DS.Spacing.md)
    }

    private var dateRow: some View {
        HStack(spacing: DS.Spacing.xxs + 2) {
            Circle()
                .fill(note.accent.color.gradient)
                .frame(width: 7, height: 7)
            Text(note.formattedDate)
                .font(DS.Typography.caption2())
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var titleText: some View {
        Text(note.title.isEmpty ? "Sans titre" : note.title)
            .font(DS.Typography.subheadline())
            .foregroundStyle(.primary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var snippetText: some View {
        Text(note.body.isEmpty ? "Appuyez pour modifier…" : note.body)
            .font(DS.Typography.footnote())
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var footerBadge: some View {
        HStack(spacing: DS.Spacing.xxs) {
            Image(systemName: "note.text")
                .font(DS.Typography.caption2())
            Text("Note")
                .font(DS.Typography.caption2().weight(.medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, DS.Spacing.xs)
        .padding(.vertical, DS.Spacing.xxs)
        .background(Color.primary.opacity(0.06), in: Capsule())
    }
}

// MARK: - Preview

#Preview(traits: .sampleNotes) {
    @Previewable @Query var notes: [Note]
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
    }
    .overlay {
        if let note = notes.first {
            NoteCard(note: note)
                .padding(DS.Spacing.xl)
        }
    }
}
