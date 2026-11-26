import SwiftUI

/// Floating bottom island of the home screen (a `safeAreaBar`, so it rides above
/// the keyboard and content scrolls under it).
///
/// Browsing: custom glass search field + the screen's one prominent action (compose).
/// Searching: the compose button morphs into a close button.
/// Selecting: "Tout sélectionner" + delete.
struct HomeBottomBar: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let hasNotes: Bool
    let isSelecting: Bool
    let allSelected: Bool
    let canDelete: Bool
    let deleteTitle: String
    @Binding var showDeleteConfirm: Bool
    let zoomNamespace: Namespace.ID
    let onCompose: () -> Void
    let onToggleSelectAll: () -> Void
    let onConfirmDelete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var controlTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity)
    }

    /// No `GlassEffectContainer` here: the compose button must stay a real view
    /// of its own to serve as the zoom-transition source (inside a container its glass
    /// is drawn by the container, UIKit finds no source view and falls back).
    /// State changes use scale + fade transitions instead of glass morphing.
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            if isSelecting {
                selectionControls
            } else {
                browsingControls
            }
        }
        // Keeps the island compact in landscape / on iPad.
        .frame(maxWidth: 640)
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.xs)
        .padding(.bottom, DS.Spacing.xxs)
        .animation(DS.Motion.morph(reduceMotion), value: isSelecting)
        .animation(DS.Motion.morph(reduceMotion), value: isSearchFocused.wrappedValue)
    }

    // MARK: Browsing

    @ViewBuilder
    private var browsingControls: some View {
        if hasNotes {
            searchField
                .transition(controlTransition)
        } else {
            Spacer(minLength: 0)
        }

        if isSearchFocused.wrappedValue {
            GlassCircleButton(title: "Fermer la recherche", systemImage: "xmark") {
                searchText = ""
                isSearchFocused.wrappedValue = false
            }
            .transition(controlTransition)
        } else {
            GlassCircleButton(title: "Nouvelle note", systemImage: "plus", prominent: true, action: onCompose)
                .matchedTransitionSource(id: ComposeZoomSource.id, in: zoomNamespace)
                .transition(controlTransition)
        }
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            // The field fills the capsule, so any tap on it focuses natively.
            TextField("Rechercher", text: $searchText)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: DS.Control.height)
                .focused(isSearchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .accessibilityLabel("Rechercher dans les notes")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Effacer la recherche")
                .transition(.opacity.combined(with: .scale(scale: 0.6)))
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity)
        .glassEffect(.control, in: .capsule)
        .animation(DS.Motion.quick(reduceMotion), value: searchText.isEmpty)
    }

    // MARK: Selecting

    @ViewBuilder
    private var selectionControls: some View {
        GlassPillButton(title: allSelected ? "Tout désélectionner" : "Tout sélectionner",
                        action: onToggleSelectAll)
            .transition(controlTransition)

        Spacer(minLength: 0)

        GlassCircleButton(title: "Supprimer les notes sélectionnées", systemImage: "trash",
                          role: .destructive) {
            showDeleteConfirm = true
        }
        .disabled(!canDelete)
        .transition(controlTransition)
        // Attached to the button so the popover points at it.
        .confirmationDialog(deleteTitle, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button(deleteTitle, role: .destructive, action: onConfirmDelete)
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible.")
        }
    }
}

/// Zoom-transition source id of the compose button (new notes grow out of it).
enum ComposeZoomSource {
    static let id = "compose"
}
