import SwiftUI
import SwiftData

/// Notes list screen — Apple Notes (iOS 26) aesthetic.
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

    // Selection mode
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<Note.ID>()
    @State private var showBatchDeleteConfirm = false

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

    private var isSelecting: Bool { editMode.isEditing }

    /// Selected notes that are still visible (a search can hide part of the selection).
    private var selectedNotes: [Note] {
        filteredNotes.filter { selection.contains($0.id) }
    }

    // MARK: Body

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if notes.isEmpty {
                    emptyState
                } else if filteredNotes.isEmpty {
                    searchEmptyState
                } else {
                    switch viewStyle {
                    case .list:    listContent
                    case .gallery: galleryContent
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Rechercher"
            )
            .toolbar { toolbarItems }
            .sensoryFeedback(.selection, trigger: selection)
            // MARK: Navigation destination
            .navigationDestination(for: Note.self) { note in
                NoteDetailView(note: note)
            }
            // Filter sheet (placeholder — its menu entry is hidden until filters exist)
            .sheet(isPresented: $showFilters) {
                filterSheetPlaceholder
            }
        }
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
    }

    // MARK: List View

    /// Both sections always exist (headers only when something is pinned), so a note
    /// moving in or out of "Épinglées" keeps its identity and animates as a move.
    private var listContent: some View {
        let groups = groupedNotes
        let hasPinned = !groups.pinned.isEmpty
        return List(selection: isSelecting ? $selection : nil) {
            Section {
                listRows(groups.pinned)
            } header: {
                if hasPinned { Text("Épinglées") }
            }

            Section {
                listRows(groups.others)
            } header: {
                if hasPinned && !groups.others.isEmpty { Text("Notes") }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.visible)
        .environment(\.editMode, $editMode)
        .animation(.default, value: groups.pinned.map(\.id) + groups.others.map(\.id))
    }

    private func listRows(_ notes: [Note]) -> some View {
        ForEach(notes) { note in
            NavigationLink(value: note) {
                NoteRowView(note: note)
            }
            // Generous inset matching Apple Notes
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 16))
            .listRowBackground(Color.clear)
            // Swipe: delete
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteNote(note)
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }
            // Swipe: pin / unpin
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                pinButton(for: note)
                    .tint(.yellow)
            }
        }
    }

    // MARK: Gallery View

    private let galleryColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 260), spacing: DS.Spacing.md)
    ]

    private var galleryContent: some View {
        let groups = groupedNotes
        return ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                if !groups.pinned.isEmpty {
                    SectionHeaderView(title: "Épinglées", count: groups.pinned.count)
                    galleryGrid(groups.pinned)
                }

                if !groups.others.isEmpty {
                    SectionHeaderView(
                        title: groups.pinned.isEmpty ? "Toutes les notes" : "Notes",
                        count: groups.others.count
                    )
                    galleryGrid(groups.others)
                }
            }
            .padding(.top, DS.Spacing.xs)
            .padding(.bottom, DS.Spacing.xxxl)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .animation(.default, value: groups.pinned.map(\.id) + groups.others.map(\.id))
    }

    private func galleryGrid(_ notes: [Note]) -> some View {
        LazyVGrid(columns: galleryColumns, spacing: DS.Spacing.md) {
            ForEach(notes) { note in
                NoteCard(note: note)
                    .overlay { selectionOverlay(isSelected: selection.contains(note.id)) }
                    .onTapGesture {
                        if isSelecting {
                            toggleSelection(of: note)
                        } else {
                            path.append(note)
                        }
                    }
                    .pressableScale()
                    // Long press: same actions as the list swipes (none while selecting)
                    .contextMenu {
                        if !isSelecting {
                            pinButton(for: note)
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
                    .accessibilityAddTraits(selection.contains(note.id) ? .isSelected : [])
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
    }

    /// Gallery selection mode: a check circle on every card, and an accent
    /// border on the selected ones.
    @ViewBuilder
    private func selectionOverlay(isSelected: Bool) -> some View {
        if isSelecting {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2.5)
                    .opacity(isSelected ? 1 : 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        isSelected ? Color.white : Color.secondary,
                        isSelected ? Color.accentColor : Color.secondary
                    )
                    .contentTransition(.symbolEffect(.replace))
                    .padding(DS.Spacing.sm)
            }
            .allowsHitTesting(false)
            .transition(reduceMotion ? .opacity : .scale(scale: 0.8).combined(with: .opacity))
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // ── Top right: ellipsis menu ──────────────────────────────────
        ToolbarItem(placement: .primaryAction) {
            if isSelecting {
                Button("Annuler", action: endSelection)
            } else {
                optionsMenu
            }
        }

        // ── Bottom bar ────────────────────────────────────────────────
        ToolbarItem(placement: .bottomBar) {
            if isSelecting {
                selectionBottomBar
            } else {
                noteCountAndCompose
            }
        }
    }

    private var optionsMenu: some View {
        Menu {
            // Sort submenu
            Menu {
                ForEach(NoteSortOrder.allCases) { order in
                    Button {
                        withAnimation { sortOrder = order }
                    } label: {
                        Label(
                            order.label,
                            systemImage: sortOrder == order ? "checkmark" : order.icon
                        )
                    }
                }
            } label: {
                Label("Trier par", systemImage: "arrow.up.arrow.down")
            }

            Divider()

            // View toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewStyle = (viewStyle == .list) ? .gallery : .list
                }
            } label: {
                Label(
                    viewStyle == .list ? "Vue galerie" : "Vue liste",
                    systemImage: viewStyle == .list ? "square.grid.2x2" : "list.bullet"
                )
            }

            // Select
            Button(action: beginSelection) {
                Label("Sélectionner des notes", systemImage: "checkmark.circle")
            }
            .disabled(notes.isEmpty)

        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 17))
        }
    }

    /// Hidden until filters are implemented (the sheet is only a placeholder).
    /// To restore, add it back to `optionsMenu`.
    private var filterMenuItem: some View {
        Button { showFilters = true } label: {
            Label("Filtrer les notes", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    /// Bottom bar: count centered, compose button right — matches Apple Notes.
    private var noteCountAndCompose: some View {
        HStack(spacing: 0) {
            Spacer()

            Text("\(notes.count) note\(notes.count != 1 ? "s" : "")")
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(DS.Animation.interactive, value: notes.count)

            Spacer()

            Button {
                createNote()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .regular))
            }
            .accessibilityLabel("Nouvelle note")
        }
    }

    /// Bottom bar in selection mode: selection count centered, delete on the right.
    private var selectionBottomBar: some View {
        HStack(spacing: 0) {
            Spacer()

            Text(selectionSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(DS.Animation.interactive, value: selectedNotes.count)

            Spacer()

            Button {
                showBatchDeleteConfirm = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 20, weight: .regular))
            }
            .tint(.red)
            .disabled(selectedNotes.isEmpty)
            .accessibilityLabel("Supprimer les notes sélectionnées")
            // Attached to the button so the iOS 26 popover points at it.
            .confirmationDialog(
                batchDeleteTitle,
                isPresented: $showBatchDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(batchDeleteTitle, role: .destructive, action: deleteSelectedNotes)
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action est irréversible.")
            }
        }
    }

    private var selectionSummary: String {
        switch selectedNotes.count {
        case 0:  "Aucune note sélectionnée"
        case 1:  "1 note sélectionnée"
        case let n: "\(n) notes sélectionnées"
        }
    }

    private var batchDeleteTitle: String {
        let count = selectedNotes.count
        return count == 1 ? "Supprimer la note" : "Supprimer les \(count) notes"
    }

    // MARK: Empty States

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "note.text")
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundStyle(.quaternary)

            VStack(spacing: DS.Spacing.xs) {
                Text("Aucune note")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Touchez l'icône de composition\npour créer votre première note.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, DS.Spacing.xxxl)
    }

    private var searchEmptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56, weight: .ultraLight))
                .foregroundStyle(.quaternary)

            VStack(spacing: DS.Spacing.xs) {
                Text("Aucun résultat")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Aucune note ne correspond à\n« \(searchText) ».")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, DS.Spacing.xxxl)
    }

    // MARK: Filter Sheet Placeholder

    private var filterSheetPlaceholder: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.lg) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(.quaternary)
                    .padding(.top, DS.Spacing.xxxl)

                Text("Filtres")
                    .font(.system(.title2, design: .rounded).weight(.semibold))

                Text("Cette fonctionnalité sera disponible prochainement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xxxl)

                Spacer()
            }
            .navigationTitle("Filtrer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("OK") { showFilters = false }
                        .font(.body.weight(.semibold))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: Actions

    /// Inserts an empty note and opens it. If it is left empty, the editor deletes it on exit.
    private func createNote() {
        path.append(viewModel.createNote())
    }

    private func pinButton(for note: Note) -> some View {
        Button {
            togglePin(note)
        } label: {
            Label(
                note.isPinned ? "Désépingler" : "Épingler",
                systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill"
            )
        }
    }

    private func togglePin(_ note: Note) {
        withAnimation {
            do {
                try viewModel.togglePin(note)
            } catch {
                viewModel.report(error)
            }
        }
    }

    private func deleteNote(_ note: Note) {
        withAnimation(.easeOut(duration: 0.2)) {
            do {
                try viewModel.delete(note)
            } catch {
                viewModel.report(error)
            }
        }
    }

    // MARK: Selection

    private func beginSelection() {
        withAnimation {
            selection.removeAll()
            editMode = .active
        }
    }

    private func endSelection() {
        withAnimation {
            editMode = .inactive
            selection.removeAll()
        }
    }

    private func toggleSelection(of note: Note) {
        withAnimation(.snappy(duration: 0.2)) {
            if selection.contains(note.id) {
                selection.remove(note.id)
            } else {
                selection.insert(note.id)
            }
        }
    }

    /// Deletes the confirmed selection, then leaves selection mode.
    private func deleteSelectedNotes() {
        let notesToDelete = selectedNotes
        withAnimation(.easeOut(duration: 0.2)) {
            do {
                try viewModel.delete(notesToDelete)
            } catch {
                viewModel.report(error)
            }
        }
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

#Preview("Light — Liste", traits: .sampleNotes) {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark — Liste", traits: .sampleNotes) {
    ContentView()
        .preferredColorScheme(.dark)
}
