import SwiftUI
import SwiftData

/// Note editor: an immersive writing surface on the plain system background.
///
/// No navigation bar. Floating glass controls adapt to what the user is doing:
/// - top: a back circle, and one contextual pill — "Edit" while reading,
///   the prominent "Done" while writing;
/// - bottom (reading only): the action island [bookmark | share | delete].
///   While writing it steps aside, so only the text and the keyboard remain.
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
    /// A brand-new note opens in the writing state, before its delayed first focus lands.
    @State private var isAwaitingFirstFocus: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 36
    /// Bumped to keep the end of the text above the keyboard (see `followCaret`).
    @State private var caretScrollRequest = 0
    private static let endOfText = "endOfText"

    init(note: Note) {
        _note = Bindable(wrappedValue: note)
        _isAwaitingFirstFocus = State(initialValue: !note.hasContent)
    }

    private var isEditing: Bool { focus != nil || isAwaitingFirstFocus }

    /// Comfortable reading measure on wide screens (iPad, landscape).
    private let maxTextWidth: CGFloat = 680

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            editor
                .onChange(of: caretScrollRequest) { _, _ in
                    withAnimation(DS.Motion.quick(reduceMotion)) {
                        proxy.scrollTo(Self.endOfText, anchor: .bottom)
                    }
                }
        }
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                metadata
                    .padding(.bottom, 14)
                titleField
                bodyField
                    .padding(.top, DS.Spacing.lg)
                // Scroll target just below the last line, with a little air.
                Color.clear
                    .frame(height: DS.Spacing.md)
                    .id(Self.endOfText)
                tapToWriteArea
            }
            .frame(maxWidth: maxTextWidth, alignment: .leading)
            .padding(.horizontal, DS.Spacing.xl - 4)
            .padding(.top, DS.Spacing.xs)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        // The floating controls sit directly over the text, with no band behind them.
        .scrollEdgeEffectHidden(true, for: .all)
        .background(DS.Surface.background.ignoresSafeArea())
        .safeAreaBar(edge: .top) { topBar }
        .safeAreaBar(edge: .bottom) { bottomBar }
        .toolbar(.hidden, for: .navigationBar)
        .animation(DS.Motion.morph(reduceMotion), value: isEditing)
        .sensoryFeedback(.impact(weight: .light), trigger: note.isPinned)
        .sensoryFeedback(.impact(weight: .medium), trigger: isDeleting)
        .task {
            // A new note opens ready to type, once the zoom has settled. (Focusing
            // immediately presents the keyboard mid-transition, which UIKit reports as
            // "Invalid UIScreen coordinate space conversion".)
            guard isAwaitingFirstFocus else { return }
            try? await Task.sleep(for: .milliseconds(450))
            if isAwaitingFirstFocus { focus = .title }
            isAwaitingFirstFocus = false
        }
        .onDisappear(perform: finishEditing)
    }

    // MARK: - Floating controls

    private var controlTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.7, anchor: .trailing).combined(with: .opacity)
    }

    private var islandTransition: AnyTransition {
        reduceMotion ? .opacity : .offset(y: 28).combined(with: .scale(scale: 0.9)).combined(with: .opacity)
    }

    private var topBar: some View {
        HStack(spacing: DS.Spacing.sm) {
            GlassCircleButton(title: String(localized: "Back"), systemImage: "chevron.left",
                              size: DS.Control.headerCircle) {
                dismiss()
            }

            Spacer(minLength: 0)

            // Separate views with a transition rather than one morphing glass shape.
            ZStack(alignment: .trailing) {
                if isEditing {
                    GlassPillButton(title: String(localized: "Done"), prominent: true,
                                    height: DS.Control.headerCircle, action: endEditing)
                        .transition(controlTransition)
                } else {
                    GlassPillButton(title: String(localized: "Edit"), height: DS.Control.headerCircle,
                                    action: beginEditing)
                        .transition(controlTransition)
                }
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.xxs)
        .padding(.bottom, DS.Spacing.xs)
    }

    /// Reading state only: while writing, the keyboard owns the bottom of the screen.
    private var bottomBar: some View {
        ZStack {
            if !isEditing {
                EditorActionIsland(
                    isPinned: note.isPinned,
                    shareText: note.shareText,
                    onTogglePin: togglePin,
                    showDeleteConfirm: $showDeleteConfirm,
                    onConfirmDelete: confirmDelete
                )
                .symbolEffectsRemoved(reduceMotion)
                .transition(islandTransition)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.xs)
    }

    // MARK: - Content

    /// Accent dot, last modification date, saved state — quiet, above the title.
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
            Label("Pinned", systemImage: "bookmark.fill")
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, DS.Spacing.xs)
                .padding(.vertical, 3)
                .background(DS.Surface.raised, in: Capsule())
                // The capsule overflows the line instead of pushing the title down.
                .padding(.vertical, -3)
                .fixedSize()
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }

    /// Display title, same voice as the home hero ("Your notes!").
    private var titleField: some View {
        TextField("Title", text: $note.title, axis: .vertical)
            .font(DS.Typography.display(titleSize))
            .tracking(-0.6)
            .foregroundStyle(.primary)
            .focused($focus, equals: .title)
            .submitLabel(.next)
            .onSubmit { focus = .body }
            .onChange(of: note.title) { _, _ in touchDate() }
    }

    private var bodyField: some View {
        TextField("Start writing…", text: $note.body, axis: .vertical)
            .font(.body)
            .lineSpacing(7)
            .foregroundStyle(.primary)
            .focused($focus, equals: .body)
            .onChange(of: note.body) { old, new in
                touchDate()
                followCaret(from: old, to: new)
            }
    }

    /// Empty space below the text: tapping it continues writing, like a sheet of paper.
    /// Tall enough that the last line can always be scrolled above the island.
    private var tapToWriteArea: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 280)
            .contentShape(Rectangle())
            .onTapGesture { resumeWritingAtEnd() }
            .accessibilityHidden(true)
    }

    // MARK: - Hidden until implemented

    /// Hidden: checklist, photo and formatting are not implemented yet.
    /// When they are, they become the writing-state island (same `EditorDisc`s,
    /// shown where the action island stands while reading).
    private var upcomingTools: some View {
        HStack(spacing: EditorDisc.gap) {
            Button("Checklist", systemImage: "checklist") {}
            Button("Add a photo", systemImage: "camera") {}
            Button("Text formatting", systemImage: "textformat") {}
        }
    }

    /// Hidden: creating a note from the editor is not wired yet
    /// (notes are created from the home screen).
    private var composeButton: some View {
        GlassCircleButton(title: String(localized: "New note"), systemImage: "plus") {}
    }

    // MARK: - Actions

    /// "Edit": resume writing where it makes sense — the title if there is none,
    /// otherwise the end of the body.
    private func beginEditing() {
        if note.title.trimmingCharacters(in: .whitespaces).isEmpty {
            focus = .title
        } else {
            resumeWritingAtEnd()
        }
    }

    /// Focuses the body (caret at the end) and, once the keyboard is up, brings
    /// the end of the text into view above it.
    private func resumeWritingAtEnd() {
        focus = .body
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            caretScrollRequest += 1
        }
    }

    /// A multi-line `TextField` in a `ScrollView` does not follow its caret: while
    /// the user types at the end of the body, keep the last line above the keyboard.
    /// (Edits elsewhere happen where the user tapped, which is already visible.)
    private func followCaret(from old: String, to new: String) {
        guard focus == .body, new.count > old.count, new.hasPrefix(old) else { return }
        caretScrollRequest += 1
    }

    /// "Done": dismisses the keyboard and returns to the reading state.
    private func endEditing() {
        isAwaitingFirstFocus = false
        focus = nil
    }

    private func togglePin() {
        viewModel.attempt { try $0.togglePin(note) }
    }

    private func confirmDelete() {
        isDeleting = true
        dismiss()
    }

    // MARK: - Helpers

    /// Updates `modifiedAt` on every real edit so sort-by-date stays current.
    private func touchDate() {
        viewModel.noteDidChange(note)
    }

    /// Runs once the editor is gone (so the deleted model is never rendered):
    /// deletes the note if requested or if it was left without content, then saves.
    /// Animated, so the home screen lets the removed card go smoothly.
    private func finishEditing() {
        withAnimation(DS.Motion.standard(reduceMotion)) {
            viewModel.attempt { try $0.finishEditing(note, deleteRequested: isDeleting) }
        }
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
