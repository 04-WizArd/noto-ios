//
//  ContentView.swift
//  Yportfolio
//
//  Created by Gabriel Theodoropoulos on 11/10/21.
//  Redesigned — Apple Notes (iOS 26) aesthetic.
//

import SwiftUI

// MARK: - Sort Order

enum NoteSortOrder: String, CaseIterable, Identifiable {
    case dateModified = "dateModified"
    case dateCreated  = "dateCreated"
    case title        = "title"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateModified: return "Date de modification"
        case .dateCreated:  return "Date de création"
        case .title:        return "Titre"
        }
    }

    var icon: String {
        switch self {
        case .dateModified: return "clock.arrow.circlepath"
        case .dateCreated:  return "calendar"
        case .title:        return "textformat.abc"
        }
    }
}

// MARK: - View Style

enum NoteViewStyle { case list, gallery }

// MARK: - ContentView

struct ContentView: View {

    // MARK: State

    @State private var notes: [Note] = [
        Note(id: UUID(), title: "Hello SwiftUI!",
             snippet: "First steps with SwiftUI. Learning the basics of declarative UI programming and building beautiful interfaces.",
             date: Date(), accent: .blue),
        Note(id: UUID(), title: "Build great apps",
             snippet: "Iterate, test, and polish. The key to great apps is attention to detail and consistent design language.",
             date: Date().addingTimeInterval(-3_600), accent: .green),
        Note(id: UUID(), title: "Take a break",
             snippet: "Short breaks improve focus and creativity. Step away from the screen, walk outside, and come back refreshed.",
             date: Date().addingTimeInterval(-7_200), accent: .orange)
    ]

    @State private var path        = NavigationPath()
    @State private var searchText  = ""
    @State private var sortOrder   = NoteSortOrder.dateModified
    @State private var viewStyle   = NoteViewStyle.list
    @State private var showFilters = false

    // MARK: Derived

    private var sortedNotes: [Note] {
        switch sortOrder {
        case .dateModified: return notes.sorted { $0.date > $1.date }
        case .dateCreated:  return notes           // creation order = array order
        case .title:
            return notes.sorted {
                $0.title.localizedCompare($1.title) == .orderedAscending
            }
        }
    }

    private var filteredNotes: [Note] {
        guard !searchText.isEmpty else { return sortedNotes }
        let q = searchText
        return sortedNotes.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.snippet.localizedCaseInsensitiveContains(q)
        }
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
            // MARK: Navigation destination
            .navigationDestination(for: UUID.self) { noteID in
                if let idx = notes.firstIndex(where: { $0.id == noteID }) {
                    NoteDetailView(note: $notes[idx]) { id in
                        withAnimation(.easeOut(duration: 0.2)) {
                            notes.removeAll { $0.id == id }
                        }
                    }
                }
            }
            // Filter sheet (UI only — future implementation)
            .sheet(isPresented: $showFilters) {
                filterSheetPlaceholder
            }
        }
    }

    // MARK: List View

    private var listContent: some View {
        List {
            ForEach(filteredNotes) { note in
                NavigationLink(value: note.id) {
                    NoteRowView(note: note)
                }
                // Generous inset matching Apple Notes
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
                // Swipe: delete
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteNote(id: note.id)
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
                // Swipe: pin (UI only)
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button { } label: {
                        Label("Épingler", systemImage: "pin.fill")
                    }
                    .tint(.yellow)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.visible)
        .animation(.default, value: filteredNotes.map(\.id))
    }

    // MARK: Gallery View

    private let galleryColumns = [
        GridItem(.adaptive(minimum: 160, maximum: 260), spacing: DS.Spacing.md)
    ]

    private var galleryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                SectionHeaderView(title: "Toutes les notes", count: filteredNotes.count)

                LazyVGrid(columns: galleryColumns, spacing: DS.Spacing.md) {
                    ForEach(filteredNotes) { note in
                        let isSelected = false
                        NoteCard(note: note, isSelected: isSelected, namespace: Namespace().wrappedValue)
                            .onTapGesture {
                                if let idx = notes.firstIndex(where: { $0.id == note.id }) {
                                    path.append(notes[idx].id)
                                }
                            }
                            .pressableScale()
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
            }
            .padding(.top, DS.Spacing.xs)
            .padding(.bottom, DS.Spacing.xxxl)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .animation(.default, value: filteredNotes.map(\.id))
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        // ── Top right: ellipsis menu ──────────────────────────────────
        ToolbarItem(placement: .primaryAction) {
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

                // Filter
                Button { showFilters = true } label: {
                    Label("Filtrer les notes", systemImage: "line.3.horizontal.decrease.circle")
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

                // Select (UI only)
                Button { } label: {
                    Label("Sélectionner des notes", systemImage: "checkmark.circle")
                }

            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17))
            }
        }

        // ── Bottom bar ────────────────────────────────────────────────
        ToolbarItem(placement: .bottomBar) {
            noteCountAndCompose
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

    private func createNote() {
        let newNote = Note(
            id: UUID(),
            title: "",
            snippet: "",
            date: Date(),
            accent: Note.randomAccent()
        )
        notes.insert(newNote, at: 0)
        path.append(newNote.id)
    }

    private func deleteNote(id: UUID) {
        withAnimation(.easeOut(duration: 0.2)) {
            notes.removeAll { $0.id == id }
        }
    }
}

// MARK: - Previews

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light — Liste")
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark — Liste")
        }
    }
}
