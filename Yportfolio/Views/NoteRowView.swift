//
//  NoteRowView.swift
//  Yportfolio
//
//  Inspired by Apple Notes list row — iOS 26 style.
//

import SwiftUI

struct NoteRowView: View {
    let note: Note

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // ── Title ─────────────────────────────────────────────────────
            HStack(spacing: 6) {
                // Accent dot (subtle category indicator)
                Circle()
                    .fill(note.accent)
                    .frame(width: 6, height: 6)

                Text(note.title.isEmpty ? "Sans titre" : note.title)
                    .font(.system(.body, design: .default).weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            // ── Date + Snippet preview (Apple Notes pattern) ──────────────
            HStack(spacing: 6) {
                Text(shortDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize()                    // never truncates date

                Text(previewText)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed

    private var previewText: String {
        note.snippet.isEmpty ? "Pas de texte supplémentaire" : note.snippet
    }

    /// Context-aware date label matching Apple Notes behavior.
    private var shortDate: String {
        let cal = Calendar.current
        let now  = Date()

        if cal.isDateInToday(note.date) {
            return formatted(note.date, format: "HH:mm")
        } else if cal.isDateInYesterday(note.date) {
            return "Hier"
        } else if let days = cal.dateComponents([.day], from: note.date, to: now).day, days < 7 {
            return formatted(note.date, format: "EEEE")
        } else {
            let f = DateFormatter()
            f.dateStyle  = .short
            f.locale     = .autoupdatingCurrent
            return f.string(from: note.date)
        }
    }

    private func formatted(_ date: Date, format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale     = .autoupdatingCurrent
        return f.string(from: date).capitalized
    }
}

// MARK: - Preview

#Preview {
    List {
        ForEach(Note.sample) { note in
            NoteRowView(note: note)
        }
    }
    .listStyle(.plain)
}
