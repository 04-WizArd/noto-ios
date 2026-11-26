import SwiftUI
import SwiftData

// Preview-only sample data. Lives in an in-memory container and is never
// inserted into the app's persistent store.

extension Note {
    static func previewSamples() -> [Note] {
        let now = Date.now
        return [
            Note(title: "Hello SwiftUI!",
                 body: "First steps with SwiftUI. Learning the basics of declarative UI programming and building beautiful interfaces.",
                 accent: .blue,
                 createdAt: now.addingTimeInterval(-86_400 * 3), modifiedAt: now),
            Note(title: "Build great apps",
                 body: "Iterate, test, and polish. The key to great apps is attention to detail and consistent design language.",
                 accent: .green,
                 createdAt: now.addingTimeInterval(-86_400 * 2), modifiedAt: now.addingTimeInterval(-3_600)),
            Note(title: "Take a break",
                 body: "Short breaks improve focus and creativity. Step away from the screen, walk outside, and come back refreshed.",
                 accent: .orange,
                 createdAt: now.addingTimeInterval(-86_400), modifiedAt: now.addingTimeInterval(-7_200)),
            Note(title: "Réunion Projet",
                 body: "Points clés, décisions et tâches à suivre…",
                 accent: .indigo,
                 createdAt: now.addingTimeInterval(-86_400 * 5), modifiedAt: now.addingTimeInterval(-86_400)),
            Note(title: "Idée d’article",
                 body: "Exploration des meilleures pratiques SwiftUI…",
                 accent: .pink,
                 createdAt: now.addingTimeInterval(-86_400 * 6), modifiedAt: now.addingTimeInterval(-86_400 * 2)),
            Note(title: "Courses",
                 body: "Pommes, lait d’amande, pâtes, tomates cerises…",
                 accent: .teal,
                 createdAt: now.addingTimeInterval(-86_400 * 7), modifiedAt: now.addingTimeInterval(-86_400 * 4))
        ]
    }
}

/// Injects an in-memory `ModelContainer` filled with `Note.previewSamples()`,
/// plus a `NotesViewModel` bound to it.
struct SampleNotesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(
            for: Note.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for note in Note.previewSamples() {
            container.mainContext.insert(note)
        }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content
            .modelContainer(context)
            .environment(NotesViewModel(modelContext: context.mainContext))
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var sampleNotes: Self { .modifier(SampleNotesPreview()) }
}
