//
//  NoteDetailView.swift
//  Yportfolio
//
//  Full-screen note editor — inspired by Apple Notes editor (iOS 26).
//

import SwiftUI

struct NoteDetailView: View {
    @Binding var note: Note
    let onDelete: (UUID) -> Void

    // MARK: - Focus & State

    enum NoteField: Hashable { case title, body }

    @FocusState private var focus: NoteField?
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

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
                onDelete(note.id)
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
        TextField("Commencer à écrire…", text: $note.snippet, axis: .vertical)
            .font(.system(size: 17, design: .default))
            .lineSpacing(5)
            .foregroundStyle(.primary)
            .focused($focus, equals: .body)
            .onChange(of: note.snippet) { _, _ in touchDate() }
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

    /// "Touch" the note date on every keystroke so sort-by-date stays current.
    private func touchDate() {
        note.date = Date()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NoteDetailView(
            note: .constant(Note.sample.first!),
            onDelete: { _ in }
        )
    }
}
