import SwiftUI

struct Note: Identifiable, Equatable {
    let id: UUID
    var title: String
    var snippet: String
    var date: Date
    var accent: Color

    init(id: UUID = UUID(), title: String, snippet: String, date: Date, accent: Color) {
        self.id = id
        self.title = title
        self.snippet = snippet
        self.date = date
        self.accent = accent
    }
}

extension Note {
    var formattedDate: String {
        let f = DateFormatter()
        f.locale = .autoupdatingCurrent
        f.dateStyle = .medium
        return f.string(from: date)
    }

    static var sample: [Note] {
        [
            Note(title: "Réunion Projet",
                 snippet: "Points clés, décisions et tâches à suivre…",
                 date: Date().addingTimeInterval(-3600),
                 accent: Color.indigo),
            Note(title: "Idée d’article",
                 snippet: "Exploration des meilleures pratiques SwiftUI…",
                 date: Date().addingTimeInterval(-86400),
                 accent: Color.pink),
            Note(title: "Courses",
                 snippet: "Pommes, lait d’amande, pâtes, tomates cerises…",
                 date: Date().addingTimeInterval(-172800),
                 accent: Color.teal)
        ]
    }

    static func randomAccent() -> Color {
        [.indigo, .pink, .teal, .purple, .orange, .blue, .mint].randomElement() ?? .blue
    }
}
