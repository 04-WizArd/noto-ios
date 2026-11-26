import SwiftUI
import SwiftData

/// Full-screen note editor — inspired by Apple Notes editor (iOS 26).
struct NoteDetailView: View {
    @Bindable var note: Note

    // MARK: - Focus & State

    enum NoteField: Hashable { case title, body }

    @FocusState private var focus: NoteField?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    /// Set when the user confirms deletion; the note is deleted once the editor is gone.
    @State private var isDeleting = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                titleField
                dateLabel
                divider
                bodyField
            }
        }
        .background(Color(UIColor.systemBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { editorToolbar }
        .confirmationDialog(
            "Supprimer cette note ?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Supprimer la note", role: .destructive) {
                isDeleting = true
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible.")
        }
        .onAppear {
            if note.title.isEmpty {
                // Short delay lets the navigation transition complete first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    focus = .title
                }
            }
        }
        .onDisappear(perform: finishEditing)
    }

    // MARK: - Subviews

    /// Expandable title field — grows vertically like Apple Notes.
    private var titleField: some View {
        TextField("Titre", text: $note.title, axis: .vertical)
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundStyle(.primary)
            .focused($focus, equals: .title)
            .submitLabel(.next)
            .onSubmit { focus = .body }
            .onChange(of: note.title) { _, _ in touchDate() }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xxs)
    }

    /// Contextual date — updates on every edit.
    private var dateLabel: some View {
        Text(note.formattedDate)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.md)
    }

    private var divider: some View {
        Divider()
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.md)
    }

    /// Main body editor — expandable, full-width.
    private var bodyField: some View {
        TextField("Commencer à écrire…", text: $note.body, axis: .vertical)
            .font(.system(size: 17, design: .default))
            .lineSpacing(5)
            .foregroundStyle(.primary)
            .focused($focus, equals: .body)
            .onChange(of: note.body) { _, _ in touchDate() }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xxxl)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        // Navigation bar – Done
        ToolbarItem(placement: .primaryAction) {
            Button("OK") { dismiss() }
                .font(.body.weight(.semibold))
        }

        // Bottom bar – single HStack keeps layout clean
        ToolbarItem(placement: .bottomBar) {
            bottomBarContent
        }
    }

    private var bottomBarContent: some View {
        HStack(spacing: 0) {
            // Destructive action
            Button {
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .accessibilityLabel("Supprimer la note")

            Spacer()

            // Formatting shortcuts (UI only — future)
            HStack(spacing: DS.Spacing.xl) {
                toolbarIcon("checklist", label: "Liste de contrôle")
                toolbarIcon("camera",    label: "Ajouter une photo")
                toolbarIcon("a.magnify", label: "Formatage du texte")
            }
            .foregroundStyle(.secondary)

            Spacer()

            // Compose new note
            Button {
                // Handled at ContentView level (UI only here)
            } label: {
                Image(systemName: "square.and.pencil")
            }
            .accessibilityLabel("Nouvelle note")
        }
        .font(.system(size: 19))
    }

    // MARK: - Helpers

    private func toolbarIcon(_ name: String, label: String) -> some View {
        Button { } label: {
            Image(systemName: name)
        }
        .accessibilityLabel(label)
    }

    /// Updates `modifiedAt` on every real edit so sort-by-date stays current.
    /// `createdAt` is never touched.
    private func touchDate() {
        note.modifiedAt = .now
    }

    /// Runs once the editor is gone (so the deleted model is never rendered):
    /// deletes the note if requested or if it was left without content.
    private func finishEditing() {
        if isDeleting || !note.hasContent {
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview(traits: .sampleNotes) {
    @Previewable @Query var notes: [Note]
    NavigationStack {
        if let note = notes.first {
            NoteDetailView(note: note)
        }
    }
}
