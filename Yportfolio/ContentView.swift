import SwiftUI
import SwiftData

/// Notes home screen.
///
/// Owns the screen state (search, sort, layout, selection, navigation) and composes:
/// - `HomeTopBar` (floating): greeting / compact title + glass control island;
/// - the content: `NotesListView` or `NotesGalleryView`, both starting with `HomeHeader`;
/// - `HomeBottomBar` (floating): glass search + prominent compose, or selection actions.
/// The navigation bar is hidden; navigation itself stays native (`NavigationStack`,
/// zoom transitions, interactive dismiss).
struct ContentView: View {

    // MARK: Data

    @Environment(NotesViewModel.self) private var viewModel
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    // MARK: State

    @State private var path        = NavigationPath()
    @State private var searchText  = ""
    @State private var sortOrder   = NoteSortOrder.dateModified
    @State private var viewStyle   = NoteViewStyle.list
    @State private var showFilters = false
    @FocusState private var isSearchFocused: Bool

    // Selection mode
    @State private var isSelecting = false
    @State private var selection = Set<Note.ID>()
    @State private var showBatchDeleteConfirm = false

    @State private var isHeaderCollapsed = false

    /// Note just created from the compose button: its editor zooms out of that button.
    @State private var composedNote: ObjectIdentifier?
    @Namespace private var zoomNamespace

    // Haptic triggers
    @State private var pinFeedback = 0
    @State private var deleteFeedback = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Derived

    private var filteredNotes: [Note] {
        guard !searchText.isEmpty else { return notes }
        let q = searchText
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.body.localizedCaseInsensitiveContains(q)
        }
    }

    /// Visible notes: pinned first, the selected sort applied inside each group.
    private var groupedNotes: (pinned: [Note], others: [Note]) {
        sortOrder.grouped(filteredNotes)
    }

    /// Selected notes that are still visible (a search can hide part of the selection).
    private var selectedNotes: [Note] {
        filteredNotes.filter { selection.contains($0.id) }
    }

    private var allVisibleSelected: Bool {
        !filteredNotes.isEmpty && selectedNotes.count == filteredNotes.count
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            content
                .background(DS.Surface.background.ignoresSafeArea())
                .safeAreaBar(edge: .top) { topBar }
                .safeAreaBar(edge: .bottom) { bottomBar }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Note.self) { note in
                    NoteDetailView(note: note)
                        .navigationTransition(.zoom(sourceID: zoomSource(for: note), in: zoomNamespace))
                }
                .sheet(isPresented: $showFilters) {
                    FilterSheetPlaceholder()
                }
        }
        .sensoryFeedback(.selection, trigger: selection)
        .sensoryFeedback(.impact(weight: .light), trigger: pinFeedback)
        .sensoryFeedback(.impact(weight: .medium), trigger: deleteFeedback)
        // Persistence failures reported by NotesViewModel (from any screen)
        .alert("Enregistrement impossible", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.lastError?.localizedDescription ?? "")
        }
        // Nothing left to select (e.g. the last notes were just deleted).
        .onChange(of: notes.isEmpty) { _, isEmpty in
            if isEmpty { endSelection() }
        }
        // Once back on the home screen, a composed note zooms from its own card next time.
        .onChange(of: path.isEmpty) { _, isEmpty in
            guard isEmpty else { return }
            Task {
                try? await Task.sleep(for: .seconds(1))
                if path.isEmpty { composedNote = nil }
            }
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        let groups = groupedNotes
        ZStack {
            if notes.isEmpty || filteredNotes.isEmpty {
                messageContent
                    .transition(.opacity)
            } else {
                switch viewStyle {
                case .list:
                    NotesListView(
                        pinned: groups.pinned, others: groups.others,
                        isSelecting: isSelecting, selection: $selection,
                        isHeaderCollapsed: $isHeaderCollapsed, zoomNamespace: zoomNamespace,
                        onOpen: open, onTogglePin: togglePin, onDelete: deleteNote
                    ) { header }
                    .transition(viewSwitchTransition)
                case .gallery:
                    NotesGalleryView(
                        pinned: groups.pinned, others: groups.others,
                        isSelecting: isSelecting, selection: $selection,
                        isHeaderCollapsed: $isHeaderCollapsed, zoomNamespace: zoomNamespace,
                        onOpen: open, onTogglePin: togglePin, onDelete: deleteNote
                    ) { header }
                    .transition(viewSwitchTransition)
                }
            }
        }
        .animation(DS.Motion.standard(reduceMotion), value: viewStyle)
        .animation(DS.Motion.standard(reduceMotion), value: notes.isEmpty)
        .animation(DS.Motion.standard(reduceMotion), value: filteredNotes.isEmpty)
    }

    private var header: some View {
        HomeHeader(count: notes.count, sortOrder: $sortOrder, showsSort: notes.count > 1)
    }

    /// Empty store or empty search: header + one calm message card.
    private var messageContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl) {
                header
                if notes.isEmpty {
                    HomeMessageCard(
                        systemImage: "square.and.pencil",
                        title: "Aucune note",
                        message: "Vos idées, listes et brouillons trouveront leur place ici."
                    ) {
                        GlassPillButton(title: "Créer une note", prominent: true, action: createNote)
                            .padding(.top, DS.Spacing.xs)
                    }
                } else {
                    HomeMessageCard(
                        systemImage: "magnifyingglass",
                        title: "Aucun résultat",
                        message: "Aucune note ne correspond à « \(searchText) »."
                    )
                }
            }
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.top, DS.Spacing.xs)
        }
        .scrollDismissesKeyboard(.interactively)
        .tracksHeaderCollapse($isHeaderCollapsed)
    }

    /// List ↔ gallery: the incoming layout rises slightly while fading in.
    private var viewSwitchTransition: AnyTransition {
        reduceMotion ? .opacity
                     : .asymmetric(insertion: .opacity.combined(with: .offset(y: 24)),
                                   removal: .opacity)
    }

    // MARK: Bars

    private var topBar: some View {
        HomeTopBar(
            isSelecting: isSelecting,
            selectionSummary: selectionSummary,
            isCollapsed: isHeaderCollapsed,
            hasNotes: !notes.isEmpty,
            viewStyle: viewStyle,
            onToggleViewStyle: switchViewStyle,
            onBeginSelection: beginSelection,
            onEndSelection: endSelection
        )
    }

    private var bottomBar: some View {
        HomeBottomBar(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            hasNotes: !notes.isEmpty,
            isSelecting: isSelecting,
            allSelected: allVisibleSelected,
            canDelete: !selectedNotes.isEmpty,
            deleteTitle: batchDeleteTitle,
            showDeleteConfirm: $showBatchDeleteConfirm,
            zoomNamespace: zoomNamespace,
            onCompose: createNote,
            onToggleSelectAll: toggleSelectAll,
            onConfirmDelete: deleteSelectedNotes
        )
    }

    private var selectionSummary: String {
        switch selectedNotes.count {
        case 0:     return "Aucune note sélectionnée"
        case 1:     return "1 note sélectionnée"
        case let n: return "\(n) notes sélectionnées"
        }
    }

    private var batchDeleteTitle: String {
        let count = selectedNotes.count
        return count == 1 ? "Supprimer la note" : "Supprimer les \(count) notes"
    }

    /// Hidden until filters are implemented (the sheet is only a placeholder).
    /// To restore, give it a place in the home top bar.
    private var filterMenuItem: some View {
        Button { showFilters = true } label: {
            Label("Filtrer les notes", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: Navigation

    private func zoomSource(for note: Note) -> AnyHashable {
        composedNote == note.zoomID ? AnyHashable(ComposeZoomSource.id) : AnyHashable(note.zoomID)
    }

    private func open(_ note: Note) {
        isSearchFocused = false
        path.append(note)
    }

    /// Inserts an empty note and opens it. If it is left empty, the editor deletes it on exit.
    private func createNote() {
        isSearchFocused = false
        let note = viewModel.createNote()
        composedNote = note.zoomID
        path.append(note)
    }

    private func switchViewStyle() {
        withAnimation(DS.Motion.standard(reduceMotion)) {
            viewStyle = viewStyle.toggled
        }
    }

    // MARK: Actions

    private func togglePin(_ note: Note) {
        withAnimation(DS.Motion.standard(reduceMotion)) {
            viewModel.attempt { try $0.togglePin(note) }
        }
        pinFeedback += 1
    }

    private func deleteNote(_ note: Note) {
        withAnimation(DS.Motion.standard(reduceMotion)) {
            viewModel.attempt { try $0.delete(note) }
        }
        deleteFeedback += 1
    }

    // MARK: Selection

    private func beginSelection() {
        isSearchFocused = false
        withAnimation(DS.Motion.morph(reduceMotion)) {
            selection.removeAll()
            isSelecting = true
        }
    }

    private func endSelection() {
        withAnimation(DS.Motion.morph(reduceMotion)) {
            isSelecting = false
            selection.removeAll()
        }
    }

    private func toggleSelectAll() {
        withAnimation(DS.Motion.quick(reduceMotion)) {
            if allVisibleSelected {
                selection.removeAll()
            } else {
                selection = Set(filteredNotes.map(\.id))
            }
        }
    }

    /// Deletes the confirmed selection, then leaves selection mode.
    private func deleteSelectedNotes() {
        let notesToDelete = selectedNotes
        withAnimation(DS.Motion.standard(reduceMotion)) {
            viewModel.attempt { try $0.delete(notesToDelete) }
        }
        deleteFeedback += 1
        endSelection()
    }

    // MARK: Error alert

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.lastError != nil },
            set: { if !$0 { viewModel.lastError = nil } }
        )
    }
}

// MARK: - Previews

#Preview("Light", traits: .sampleNotes) {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark", traits: .sampleNotes) {
    ContentView()
        .preferredColorScheme(.dark)
}
