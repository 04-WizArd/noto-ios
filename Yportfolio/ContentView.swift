//
//  ContentView.swift
//  Yportfolio
//
//  Created by Gabriel Theodoropoulos on 11/10/21.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Grid

    private let gridColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 160, maximum: 260), spacing: DS.Spacing.md)
    ]

    // MARK: - State

    @Namespace private var ns
    @State private var notes = [
        Note(id: UUID(), title: "Hello SwiftUI!", snippet: "First steps with SwiftUI.", date: Date(), accent: .blue),
        Note(id: UUID(), title: "Build great apps", snippet: "Iterate, test, and polish.", date: Date().addingTimeInterval(-3600), accent: .green),
        Note(id: UUID(), title: "Take a break", snippet: "Short breaks improve focus.", date: Date().addingTimeInterval(-7200), accent: .orange)
    ]

    @State private var showDetail = false
    @State private var selectedNote: Note?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // ── Background ──────────────────────────────────────────
                BackgroundView()

                // ── Scroll content ──────────────────────────────────────
                ScrollView {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        SectionHeaderView(title: "Toutes les notes", count: notes.count)

                        LazyVGrid(columns: gridColumns, spacing: DS.Spacing.md) {
                            ForEach(notes, id: \.id) { note in
                                noteCard(for: note)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.lg)
                    }
                    .padding(.top, DS.Spacing.xs)
                    // Bottom inset so last card clears the toolbar
                    .padding(.bottom, DS.Spacing.xxxl + DS.Spacing.xl)
                }
                .scrollContentBackground(.hidden)
            }
            // ── Animated overlay ────────────────────────────────────────
            .overlay {
                if showDetail, let selectedNote {
                    NoteDetailOverlay(note: selectedNote, namespace: ns) {
                        withAnimation(DS.Animation.overlay) {
                            showDetail = false
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(10)
                }
            }
            // ── Navigation ──────────────────────────────────────────────
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(DS.Material.toolbar, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    FloatingAddButton(namespace: ns) {
                        let newNote = Note(
                            id: UUID(),
                            title: "",
                            snippet: "",
                            date: Date(),
                            accent: Note.randomAccent()
                        )
                        notes.append(newNote)
                        selectedNote = newNote
                        withAnimation(DS.Animation.overlay) {
                            showDetail = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Note Card Builder

    @ViewBuilder
    private func noteCard(for note: Note) -> some View {
        let isSelected = selectedNote?.id == note.id
        NoteCard(note: note, isSelected: isSelected, namespace: ns)
            .onTapGesture {
                selectedNote = note
                withAnimation(DS.Animation.overlay) {
                    showDetail = true
                }
            }
            .pressableScale()
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light")
            ContentView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
