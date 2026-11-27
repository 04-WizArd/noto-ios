import SwiftUI

/// Floating action island of the editor (reading state): one glass capsule holding
/// equal circular discs — bookmark, share, delete.
///
/// Same construction as the home dock: the glass is a separate layer *behind* the
/// discs (content inside a glass effect is rendered vibrant, which would grey out
/// the solid disc), and no `GlassEffectContainer` (morphing glass while the keyboard
/// takes focus is what produced "glassEffect() tried to update multiple times per frame").
/// New editor tools can be added as more `EditorDisc`s without changing the layout.
struct EditorActionIsland: View {
    let isPinned: Bool
    let shareText: String
    let onTogglePin: () -> Void
    @Binding var showDeleteConfirm: Bool
    let onConfirmDelete: () -> Void

    var body: some View {
        HStack(spacing: EditorDisc.gap) {
            // Saved state: a solid disc when bookmarked, like the active key of the reference.
            Button(action: onTogglePin) {
                EditorDisc(systemImage: isPinned ? "bookmark.fill" : "bookmark",
                           style: isPinned ? .solid : .soft)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: isPinned)
            }
            .buttonStyle(.dock)
            .accessibilityLabel(isPinned ? String(localized: "Unpin") : String(localized: "Pin"))
            .accessibilityShowsLargeContentViewer {
                Label(isPinned ? String(localized: "Unpin") : String(localized: "Pin"),
                      systemImage: isPinned ? "bookmark.fill" : "bookmark")
            }

            ShareLink(item: shareText) {
                EditorDisc(systemImage: "square.and.arrow.up", style: .soft)
            }
            .buttonStyle(.dock)
            .disabled(shareText.isEmpty)
            .accessibilityLabel("Share note")
            .accessibilityShowsLargeContentViewer {
                Label("Share note", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                EditorDisc(systemImage: "trash", style: .destructive)
            }
            .buttonStyle(.dock)
            .accessibilityLabel("Delete note")
            .accessibilityShowsLargeContentViewer {
                Label("Delete note", systemImage: "trash")
            }
            // Attached to the button so the popover points at it.
            .confirmationDialog("Delete this note?", isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete note", role: .destructive, action: onConfirmDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action can't be undone.")
            }
        }
        .padding(EditorDisc.gap)
        .background {
            Capsule()
                .fill(.clear)
                .glassEffect(.regular, in: .capsule)
        }
    }
}

/// One circular key of the editor island. Every disc has the same diameter, so
/// symbols sit in identical frames and the island stays optically balanced.
struct EditorDisc: View {
    enum Style { case solid, soft, destructive }

    let systemImage: String
    var style: Style = .soft

    static let size: CGFloat = DS.Control.headerCircle
    static let gap: CGFloat = 6

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(foreground)
            .frame(width: Self.size, height: Self.size)
            .background(background, in: Circle())
            .overlay {
                Circle().strokeBorder(Color.primary.opacity(style == .solid ? 0 : 0.08), lineWidth: 1)
            }
            .contentShape(Circle())
    }

    private var foreground: Color {
        switch style {
        case .solid:       return DS.Surface.background
        case .soft:        return .primary
        case .destructive: return .red
        }
    }

    private var background: Color {
        switch style {
        case .solid:       return .primary
        case .soft:        return .primary.opacity(0.06)
        case .destructive: return .red.opacity(0.1)
        }
    }
}

#Preview {
    @Previewable @State var pinned = false
    @Previewable @State var confirm = false
    EditorActionIsland(isPinned: pinned, shareText: "Note", onTogglePin: { pinned.toggle() },
                       showDeleteConfirm: $confirm, onConfirmDelete: {})
        .padding()
}
