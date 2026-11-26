//
//  NoteDetailOverlay.swift
//  Yportfolio
//
//  ⚠️ DEPRECATED — Superseded by NoteDetailView (push navigation).
//  Kept for reference. Not used in the active UI.
//

import SwiftUI

/// Legacy bottom-sheet overlay. No longer referenced in ContentView.
/// Use NoteDetailView for full-screen note editing.
@available(*, deprecated, renamed: "NoteDetailView")
struct NoteDetailOverlay: View {
    let note: Note
    let namespace: Namespace.ID
    let onClose: () -> Void

    var body: some View {
        EmptyView()
    }
}
