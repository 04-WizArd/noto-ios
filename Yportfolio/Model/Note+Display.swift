import Foundation

/// Read-only presentation helpers shared by the list, the gallery and the editor.
extension Note {

    /// Title shown in lists and cards.
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Sans titre" : trimmed
    }

    /// Body collapsed to a single paragraph (line breaks → spaces) for previews.
    /// Empty when the body has no visible text.
    var bodyPreview: String {
        body.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Up to `limit` short lines summarising the body, for the dashboard's line pills:
    /// the body's own lines (list markers removed); a single paragraph is split on
    /// its sentences, or, if it has only one, on its commas ("a, b, c").
    func highlights(limit: Int = 3) -> [String] {
        let markers: [String] = ["- ", "• ", "* ", "– ", "— "]
        var lines = body.split(whereSeparator: \.isNewline)
            .map { line -> String in
                var text = line.trimmingCharacters(in: .whitespaces)
                if let marker = markers.first(where: text.hasPrefix) {
                    text = String(text.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
                }
                return text
            }
            .filter { !$0.isEmpty }

        if lines.count == 1, let line = lines.first {
            let byComma = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let bySentence = line.split(separator: ". ").map { $0.trimmingCharacters(in: .whitespaces) }
            if bySentence.count > 1 {
                lines = bySentence
            } else if byComma.count > 1 {
                lines = byComma
            }
        }

        return lines
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".…;").union(.whitespaces)) }
            .filter { !$0.isEmpty }
            .prefix(limit)
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
    }

    /// Short, context-aware modification date (time today, "Hier", weekday this week,
    /// numeric date otherwise), formatted with the user's locale.
    var shortModifiedDate: String {
        let calendar = Calendar.current
        let date = modifiedAt
        if calendar.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        if calendar.isDateInYesterday(date) {
            return "Hier"
        }
        if let days = calendar.dateComponents([.day], from: date, to: .now).day, days < 7 {
            return date.formatted(.dateTime.weekday(.wide)).capitalized
        }
        return date.formatted(date: .numeric, time: .omitted)
    }
}

extension Note {
    /// Stable identity for zoom transitions. Unlike `persistentModelID`, it does not
    /// change when a newly inserted note is saved for the first time.
    var zoomID: ObjectIdentifier { ObjectIdentifier(self) }
}
