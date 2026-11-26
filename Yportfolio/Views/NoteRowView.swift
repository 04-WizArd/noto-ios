import SwiftUI
import SwiftData

/// List card: neutral raised surface (the list is the calm, dense reading mode;
/// colour is reserved for the gallery), title, two-line preview, accent dot + date.
/// The top-trailing corner is left free for the pin / selection control.
struct NoteRowView: View {
    let note: Note
    var isSelected = false

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.row, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.displayTitle)
                .font(DS.Typography.rowTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .padding(.trailing, 34)   // pin control

            Text(note.bodyPreview.isEmpty ? "Pas de texte supplémentaire" : note.bodyPreview)
                .font(DS.Typography.preview)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                Circle()
                    .fill(note.accent.color)
                    .frame(width: 7, height: 7)
                    .accessibilityHidden(true)
                Text(note.shortModifiedDate)
                    .font(DS.Typography.metadata)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, DS.Spacing.md)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Surface.raised, in: shape)
        .overlay {
            shape.strokeBorder(Color.accentColor, lineWidth: 3)
                .opacity(isSelected ? 1 : 0)
        }
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .sampleNotes) {
    @Previewable @Query var notes: [Note]
    ScrollView {
        VStack(spacing: 10) {
            ForEach(notes) { NoteRowView(note: $0) }
        }
        .padding()
    }
}
