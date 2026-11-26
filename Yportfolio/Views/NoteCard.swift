import SwiftUI
import SwiftData

/// Gallery card. A soft, note-specific colour (pastel in Light Mode, deep tone in
/// Dark Mode), bold title with the date tucked underneath, and a preview whose
/// placement depends on the card's slot in the rhythm:
/// - `.tall`: title at the top, preview anchored at the bottom (editorial block);
/// - `.wide`: compact horizontal reading — title, date, two preview lines.
/// The top-trailing corner is left free for the pin / selection control.
struct NoteCard: View {
    let note: Note
    var slot: RhythmLayout.Slot = .tall
    var isSelected = false

    @Environment(\.colorScheme) private var colorScheme

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(note.displayTitle)
                .font(slot == .tall ? DS.Typography.cardTitle : DS.Typography.wideTitle)
                .foregroundStyle(.primary)
                .lineLimit(slot == .tall ? 3 : 2)
                .padding(.trailing, 34)   // pin control

            Text(note.shortModifiedDate)
                .font(DS.Typography.metadata)
                .foregroundStyle(.secondary)
                .padding(.top, 6)

            if slot == .tall {
                Spacer(minLength: DS.Spacing.sm)
            }

            if !note.bodyPreview.isEmpty {
                Text(note.bodyPreview)
                    .font(DS.Typography.preview)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .lineLimit(slot == .tall ? 4 : 2)
                    .padding(.top, slot == .tall ? 0 : 10)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: slot == .tall ? .infinity : nil, alignment: .topLeading)
        .background(DS.Surface.tint(note.accent.color, colorScheme), in: shape)
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
        RhythmLayout(tallHeight: 212) {
            ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                NoteCard(note: note, slot: RhythmLayout.slot(at: index, count: notes.count))
            }
        }
        .padding()
    }
}
