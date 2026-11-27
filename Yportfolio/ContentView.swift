import SwiftUI
import SwiftData

/// Notes home screen.
///
/// Owns the screen state (filter, search, sort, layout, selection, navigation) and composes:
/// - `HomeTopBar` (floating, no bar behind it): the glass options circle;
/// - the content, scrolling: `HomeHeader` (avatar, greeting, hero title, filter chips), `HomeDashboard`
///   (the first three notes as featured cards), `CapturePromptCard`, then the other
///   notes in `NotesListView` or `NotesGalleryView`;
/// - `HomeBottomBar` (floating): the dock (compose, search, layout), the search
///   field, or the selection actions.
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
    @State private var filter      = NoteFilter.all
    @State private var showFilters = false
    @State private var isSearching = false
    @FocusState private var isSearchFocused: Bool

    // Quick capture
    @State private var captureText = ""
    @FocusState private var isCaptureFocused: Bool

    // Selection mode
    @State private var isSelecting = false
    @State private var selection = Set<Note.ID>()
    @State private var showBatchDeleteConfirm = false

    /// Note just created from the compose button: its editor zooms out of that button.
    @State private var composedNote: ObjectIdentifier?
    @Namespace private var zoomNamespace

    // Haptic triggers
    @State private var pinFeedback = 0
    @State private var deleteFeedback = 0
    @State private var captureFeedback = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: Derived

    /// Notes matching the filter chip and the search text.
    private var filteredNotes: [Note] {
        let matching = filter.apply(to: notes)
        guard !searchText.isEmpty else { return matching }
        let q = searchText
        return matching.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.body.localizedCaseInsensitiveContains(q)
        }
    }

    /// Visible notes in display order: pinned first, the selected sort inside each group.
    private var orderedNotes: [Note] {
        let groups = sortOrder.grouped(filteredNotes)
        return groups.pinned + groups.others
    }

    /// Search results are a plain list: no dashboard, no capture card.
    private var showsDashboard: Bool { searchText.isEmpty }

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
                // No band behind the floating controls, top or bottom: they sit
                // directly over the content.
                .scrollEdgeEffectHidden(true, for: .all)
                .background(DS.Surface.background.ignoresSafeArea())
                // An overlay, not a bar: the control floats over the header's identity
                // row (which keeps room for it) and over the content as it scrolls.
                .overlay(alignment: .top) { topBar }
                .safeAreaBar(edge: .bottom) {
                    // Out of the way while typing a quick note.
                    if !isCaptureFocused {
                        bottomBar
                            .transition(.opacity)
                    }
                }
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
        .sensoryFeedback(.success, trigger: captureFeedback)
        // Persistence failures reported by NotesViewModel (from any screen)
        .alert("Couldn't save", isPresented: isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.lastError?.localizedDescription ?? "")
        }
        // Nothing left to select (e.g. the last notes were just deleted).
        .onChange(of: notes.isEmpty) { _, isEmpty in
            if isEmpty {
                endSelection()
                filter = .all
            }
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
        let ordered = orderedNotes
        let featured = showsDashboard ? Array(ordered.prefix(HomeDashboard.maxCount)) : []
        let remaining = Array(ordered.dropFirst(featured.count))
        let label = showsDashboard ? String(localized: "Other notes") : String(localized: "Results")
        ZStack {
            if ordered.isEmpty {
                messageContent
                    .transition(.opacity)
            } else {
                switch viewStyle {
                case .list:
                    NotesListView(
                        notes: remaining, label: label,
                        isSelecting: isSelecting, selection: $selection, zoomNamespace: zoomNamespace,
                        onOpen: open, onTogglePin: togglePin, onDelete: deleteNote
                    ) { header(featured: featured) }
                    .transition(viewSwitchTransition)
                case .gallery:
                    NotesGalleryView(
                        notes: remaining, label: label,
                        isSelecting: isSelecting, selection: $selection, zoomNamespace: zoomNamespace,
                        onOpen: open, onTogglePin: togglePin, onDelete: deleteNote
                    ) { header(featured: featured) }
                    .transition(viewSwitchTransition)
                }
            }
        }
        .animation(DS.Motion.standard(reduceMotion), value: viewStyle)
        .animation(DS.Motion.standard(reduceMotion), value: sortOrder)
        .animation(DS.Motion.standard(reduceMotion), value: notes.isEmpty)
        .animation(DS.Motion.standard(reduceMotion), value: filteredNotes.isEmpty)
    }

    /// Everything above the remaining notes: hero, filters, dashboard, capture.
    private func header(featured: [Note]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xl - 4) {
            HomeHeader(totalCount: notes.count, filter: $filter,
                       selectionSummary: isSelecting ? selectionSummary : nil)

            if !featured.isEmpty {
                HomeDashboard(
                    notes: featured,
                    // In list view the dashboard shares one List row (see NoteTile).
                    showsContextMenus: viewStyle == .gallery,
                    isSelecting: isSelecting, selection: $selection, zoomNamespace: zoomNamespace,
                    onOpen: open, onTogglePin: togglePin, onDelete: deleteNote
                )
            }

            if showsDashboard && !isSelecting {
                captureCard
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
    }

    private var captureCard: some View {
        CapturePromptCard(text: $captureText, isFocused: $isCaptureFocused, onSubmit: captureNote)
    }

    /// Nothing to show (empty store, empty filter, no search result): hero + one calm card.
    private var messageContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.xl - 4) {
                HomeHeader(totalCount: notes.count, filter: $filter, showsFilters: !notes.isEmpty)
                if notes.isEmpty {
                    captureCard
                    HomeMessageCard(
                        systemImage: "square.and.pencil",
                        title: String(localized: "No notes"),
                        message: String(localized: "Your ideas, lists and drafts will find their place here.")
                    ) {
                        GlassPillButton(title: String(localized: "Create a note"), prominent: true, action: createNote)
                            .padding(.top, DS.Spacing.xs)
                    }
                } else if !searchText.isEmpty {
                    HomeMessageCard(
                        systemImage: "magnifyingglass",
                        title: String(localized: "No results"),
                        message: String(localized: "No notes match “\(searchText)”.")
                    )
                } else {
                    HomeMessageCard(
                        systemImage: filter == .pinned ? "bookmark" : "clock",
                        title: filter == .pinned ? String(localized: "No pinned notes")
                                                 : String(localized: "Nothing recent"),
                        message: filter == .pinned
                            ? String(localized: "Pin a note to keep it at the top.")
                            : String(localized: "Notes edited in the last seven days will appear here.")
                    )
                }
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.top, DS.Spacing.xs)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
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
            hasNotes: !notes.isEmpty,
            sortOrder: $sortOrder,
            onBeginSelection: beginSelection,
            onEndSelection: endSelection
        )
    }

    private var bottomBar: some View {
        HomeBottomBar(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused,
            isSearching: $isSearching,
            hasNotes: !notes.isEmpty,
            isSelecting: isSelecting,
            viewStyle: viewStyle,
            allSelected: allVisibleSelected,
            canDelete: !selectedNotes.isEmpty,
            deleteTitle: batchDeleteTitle,
            showDeleteConfirm: $showBatchDeleteConfirm,
            zoomNamespace: zoomNamespace,
            onCompose: createNote,
            onToggleViewStyle: switchViewStyle,
            onToggleSelectAll: toggleSelectAll,
            onConfirmDelete: deleteSelectedNotes
        )
    }

    private var selectionSummary: String {
        let count = selectedNotes.count
        return count == 0 ? String(localized: "No notes selected")
                          : String(localized: "\(count) notes selected")
    }

    private var batchDeleteTitle: String {
        let count = selectedNotes.count
        return count == 1 ? String(localized: "Delete note") : String(localized: "Delete \(count) notes")
    }

    /// Hidden until filters are implemented (the sheet is only a placeholder).
    /// To restore, give it a place in the home top bar.
    private var filterMenuItem: some View {
        Button { showFilters = true } label: {
            Label("Filter notes", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: Navigation

    private func zoomSource(for note: Note) -> AnyHashable {
        composedNote == note.zoomID ? AnyHashable(ComposeZoomSource.id) : AnyHashable(note.zoomID)
    }

    private func open(_ note: Note) {
        isSearchFocused = false
        isCaptureFocused = false
        path.append(note)
    }

    /// Inserts an empty note and opens it. If it is left empty, the editor deletes it on exit.
    private func createNote() {
        isSearchFocused = false
        isCaptureFocused = false
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

    /// Saves the quick-capture text as a new note, staying on the home screen.
    private func captureNote() {
        let text = captureText
        withAnimation(DS.Motion.standard(reduceMotion)) {
            viewModel.attempt { try $0.capture(text) }
            // A new note is neither pinned nor old: make sure it is visible.
            if filter == .pinned { filter = .all }
        }
        captureText = ""
        isCaptureFocused = false
        captureFeedback += 1
    }

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
        isCaptureFocused = false
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
