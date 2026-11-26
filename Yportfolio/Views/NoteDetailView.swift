import SwiftUI
import SwiftData

/// Note editor: an immersive writing surface.
///
/// No navigation bar: the content (display title, body) sits on the plain system
/// background, and two floating glass objects carry every action:
/// - leading: a back circle;
/// - trailing: an island [pin | delete] while reading, which morphs into one
///   prominent "Terminé" pill while writing (keyboard up).
struct NoteDetailView: View {
    @Bindable var note: Note

    // MARK: - Focus & State

    enum NoteField: Hashable { case title, body }

    @FocusState private var focus: NoteField?
    @Environment(NotesViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showDeleteConfirm = false
    /// Set when the user confirms deletion; the note is deleted once the editor is gone.
    @State private var isDeleting = false
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = DS.Typography.displaySize

    private var isEditing: Bool { focus != nil }

    private var controlTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.7, anchor: .trailing).combined(with: .opacity)
    }

    /// Comfortable reading measure on wide screens (iPad, landscape).
    private let maxTextWidth: CGFloat = 680

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                metadata
                    .padding(.bottom, DS.Spacing.sm)
                titleField
                bodyField
                    .padding(.top, DS.Spacing.lg)
                tapToWriteArea
            }
            .frame(maxWidth: maxTextWidth, alignment: .leading)
            .padding(.horizontal, DS.Spacing.xl - 4)
            .padding(.top, DS.Spacing.sm)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DS.Surface.background.ignoresSafeArea())
        .safeAreaBar(edge: .top) { topBar }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .light), trigger: note.isPinned)
        .task {
            // A new note opens ready to type, once the zoom has settled. (Focusing
            // immediately presents the keyboard mid-transition, which UIKit reports as
            // "Invalid UIScreen coordinate space conversion".)
            guard !note.hasContent else { return }
            try? await Task.sleep(for: .milliseconds(450))
            focus = .title
        }
        .onDisappear(perform: finishEditing)
    }

    // MARK: - Floating controls

    private var topBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            GlassCircleButton(title: "Retour", systemImage: "chevron.left") {
                dismiss()
            }

            Spacer(minLength: 0)

            ZStack(alignment: .trailing) {
                if isEditing {
                    GlassPillButton(title: "Terminé", prominent: true) {
                        focus = nil
                    }
                    .transition(controlTransition)
                } else {
                    actionIsland
                        .transition(controlTransition)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
        .animation(DS.Motion.morph(reduceMotion), value: isEditing)
    }

    private var actionIsland: some View {
        ControlIsland {
            Button {
                viewModel.attempt { try $0.togglePin(note) }
            } label: {
                Label(note.isPinned ? "Désépingler" : "Épingler",
                      systemImage: note.isPinned ? "pin.fill" : "pin")
                    .contentTransition(.symbolEffect(.replace))
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Supprimer la note", systemImage: "trash")
            }
            // Attached to the button so the popover points at it.
            .confirmationDialog("Supprimer cette note ?", isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Supprimer la note", role: .destructive) {
                    isDeleting = true
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est irréversible.")
            }
        }
    }

    // MARK: - Content

    /// Accent dot, last modification date, pinned state — quiet, above the title.
    /// Stacks vertically when it does not fit on one line (large text sizes).
    private var metadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DS.Spacing.xs) {
                dateLine
                pinnedChip
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                dateLine
                pinnedChip
            }
        }
        .font(DS.Typography.metadata)
        .foregroundStyle(.secondary)
        .animation(DS.Motion.quick(reduceMotion), value: note.isPinned)
    }

    private var dateLine: some View {
        HStack(spacing: DS.Spacing.xs) {
            Circle()
                .fill(note.accent.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(note.modifiedAt, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                .contentTransition(.numericText())
        }
    }

    @ViewBuilder
    private var pinnedChip: some View {
        if note.isPinned {
            Label("Épinglée", systemImage: "pin.fill")
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, DS.Spacing.xs)
                .padding(.vertical, 3)
                .background(DS.Surface.raised, in: Capsule())
                .fixedSize()
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }

    /// Display-size title, same scale as the home screen title.
    private var titleField: some View {
        TextField("Titre", text: $note.title, axis: .vertical)
            .font(DS.Typography.display(titleSize))
            .foregroundStyle(.primary)
            .focused($focus, equals: .title)
            .submitLabel(.next)
            .onSubmit { focus = .body }
            .onChange(of: note.title) { _, _ in touchDate() }
    }

    private var bodyField: some View {
        TextField("Commencer à écrire…", text: $note.body, axis: .vertical)
            .font(.body)
            .lineSpacing(6)
            .foregroundStyle(.primary)
            .focused($focus, equals: .body)
            .onChange(of: note.body) { _, _ in touchDate() }
    }

    /// Empty space below the text: tapping it continues writing, like a sheet of paper.
    private var tapToWriteArea: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 280)
            .contentShape(Rectangle())
            .onTapGesture { focus = .body }
            .accessibilityHidden(true)
    }

    // MARK: - Hidden until implemented

    /// Hidden: checklist, photo and formatting are not implemented yet.
    /// Kept (not displayed) so the future editor commands have a place to land.
    private var upcomingTools: some View {
        ControlIsland {
            Button("Liste de contrôle", systemImage: "checklist") {}
            Button("Ajouter une photo", systemImage: "camera") {}
            Button("Formatage du texte", systemImage: "textformat") {}
        }
    }

    /// Hidden: creating a note from the editor is not wired yet
    /// (notes are created from the home screen).
    private var composeButton: some View {
        GlassCircleButton(title: "Nouvelle note", systemImage: "plus") {}
    }

    // MARK: - Helpers

    /// Updates `modifiedAt` on every real edit so sort-by-date stays current.
    private func touchDate() {
        viewModel.noteDidChange(note)
    }

    /// Runs once the editor is gone (so the deleted model is never rendered):
    /// deletes the note if requested or if it was left without content, then saves.
    private func finishEditing() {
        viewModel.attempt { try $0.finishEditing(note, deleteRequested: isDeleting) }
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
