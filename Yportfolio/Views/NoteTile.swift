import SwiftUI
import SwiftData

/// Interactive shell shared by the gallery cards and the home dashboard cards:
/// tap to open (or to toggle selection), pin / selection control in the corner,
/// context menu (pin, delete), zoom-transition source and accessibility actions.
/// The visual card itself is supplied by `content`.
struct NoteTile<Content: View>: View {
    let note: Note
    var cornerRadius: CGFloat = DS.Radius.card
    /// Long-press context menu (pin, delete). Must be `false` for cards sharing a
    /// `List` row (the home dashboard in list view): a List hoists every `.contextMenu`
    /// of a row to the whole cell, so every card would open — and act on — the first
    /// card's menu. Those cards keep the pin control, selection and the VoiceOver action.
    var showsContextMenu = true
    let isSelecting: Bool
    @Binding var selection: Set<Note.ID>
    let zoomNamespace: Namespace.ID
    let onOpen: (Note) -> Void
    let onTogglePin: (Note) -> Void
    let onDelete: (Note) -> Void
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isSelected: Bool { isSelecting && selection.contains(note.id) }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        control
            .overlay(alignment: .topTrailing) {
                Group {
                    if isSelecting {
                        SelectionIndicator(isSelected: isSelected)
                    } else {
                        PinToggle(isPinned: note.isPinned) { onTogglePin(note) }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
                .padding(6)
            }
            .accessibilityActions {
                if !isSelecting {
                    Button("Supprimer", role: .destructive) { onDelete(note) }
                }
            }
            .accessibilityValue(note.isPinned ? "Épinglée" : "")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Control

    @ViewBuilder
    private var control: some View {
        let button = Button(action: activate) { label }
            .buttonStyle(.card)
        if showsContextMenu {
            button.contextMenu { menuItems }
        } else {
            button
        }
    }

    private var label: some View {
        content
            .contentShape(shape)
            .overlay {
                shape.strokeBorder(Color.accentColor, lineWidth: 3)
                    .opacity(isSelected ? 1 : 0)
            }
            .scaleEffect(isSelected && !reduceMotion ? 0.97 : 1)
            .matchedTransitionSource(id: note.zoomID, in: zoomNamespace) { source in
                source.clipShape(shape)
            }
    }

    @ViewBuilder
    private var menuItems: some View {
        if !isSelecting {
            Button {
                onTogglePin(note)
            } label: {
                Label(note.isPinned ? "Désépingler" : "Épingler",
                      systemImage: note.isPinned ? "bookmark.slash" : "bookmark")
            }
            Button(role: .destructive) {
                onDelete(note)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }

    private func activate() {
        if isSelecting {
            withAnimation(DS.Motion.quick(reduceMotion)) { selection.toggle(note.id) }
        } else {
            onOpen(note)
        }
    }
}
