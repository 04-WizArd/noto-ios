import SwiftUI

/// Floating bottom bar of the home screen (a `safeAreaBar`, so it rides above
/// the keyboard and content scrolls under it).
///
/// Browsing — the dock: a glass capsule centred on screen holding two large discs,
/// compose (solid, the screen's one prominent action) and search; a smaller glass
/// circle beside it switches between list and gallery.
/// Searching: a glass search field and a close button.
/// Selecting: "Select all" + delete.
struct HomeBottomBar: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    @Binding var isSearching: Bool
    let hasNotes: Bool
    let isSelecting: Bool
    let viewStyle: NoteViewStyle
    let allSelected: Bool
    let canDelete: Bool
    let deleteTitle: String
    @Binding var showDeleteConfirm: Bool
    let zoomNamespace: Namespace.ID
    let onCompose: () -> Void
    let onToggleViewStyle: () -> Void
    let onToggleSelectAll: () -> Void
    let onConfirmDelete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Large discs in portrait; compact ones in landscape, where height is scarce.
    private var isCompact: Bool { verticalSizeClass == .compact }
    private var discSize: CGFloat { isCompact ? DS.Dock.compactButton : DS.Dock.button }

    private var controlTransition: AnyTransition {
        reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity)
    }

    /// No `GlassEffectContainer` here: the compose disc must stay a real view of its
    /// own to serve as the zoom-transition source (inside a container UIKit finds no
    /// source view and falls back). State changes use scale + fade transitions.
    var body: some View {
        ZStack {
            if isSelecting {
                selectionControls
                    .transition(controlTransition)
            } else if isSearching {
                searchControls
                    .transition(controlTransition)
            } else {
                dock
                    .transition(controlTransition)
            }
        }
        // Keeps the bar compact in landscape / on iPad.
        .frame(maxWidth: 640)
        .padding(.top, DS.Spacing.xs)
        .animation(DS.Motion.morph(reduceMotion), value: isSelecting)
        .animation(DS.Motion.morph(reduceMotion), value: isSearching)
    }

    // MARK: Dock

    /// Capsule centred on the screen; the accessory circle centred in the space
    /// on its right (the left side stays open, like the reference composition).
    private var dock: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: 1)

            HStack(spacing: DS.Dock.inset) {
                composeDisc
                if hasNotes {
                    searchDisc
                }
            }
            .padding(DS.Dock.inset)
            // Glass drawn as a separate layer *behind* the discs: content inside a
            // glass effect is rendered vibrant, which would wash the solid compose disc grey.
            .background {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: .capsule)
            }

            ZStack {
                if hasNotes {
                    GlassCircleButton(title: viewStyle.switchLabel, systemImage: viewStyle.switchIcon,
                                      size: DS.Dock.accessory, action: onToggleViewStyle)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var composeDisc: some View {
        Button(action: onCompose) {
            Image(systemName: "plus")
                .font(.system(size: isCompact ? 24 : 32, weight: .regular))
                .foregroundStyle(DS.Surface.background)
                .frame(width: discSize, height: discSize)
                .background {
                    Circle()
                        .fill(Color.primary)
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                }
                .overlay {
                    // Thin specular rim, like the glossy key of the reference.
                    Circle().strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.35), .clear, .white.opacity(0.12)],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.dock)
        .matchedTransitionSource(id: ComposeZoomSource.id, in: zoomNamespace)
        .accessibilityLabel("New note")
        .accessibilityShowsLargeContentViewer {
            Label("New note", systemImage: "plus")
        }
    }

    private var searchDisc: some View {
        Button {
            isSearching = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: isCompact ? 20 : 26, weight: .regular))
                .foregroundStyle(.primary)
                .frame(width: discSize, height: discSize)
                .background(Color.primary.opacity(0.06), in: Circle())
                .overlay { Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 1) }
                .contentShape(Circle())
        }
        .buttonStyle(.dock)
        .accessibilityLabel("Search")
        .accessibilityShowsLargeContentViewer {
            Label("Search", systemImage: "magnifyingglass")
        }
    }

    // MARK: Searching

    private var searchControls: some View {
        HStack(spacing: DS.Spacing.sm) {
            searchField
            GlassCircleButton(title: String(localized: "Close search"), systemImage: "xmark") {
                searchText = ""
                isSearchFocused.wrappedValue = false
                isSearching = false
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.bottom, DS.Spacing.xxs)
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            // The field fills the capsule, so any tap on it focuses natively.
            TextField("Search", text: $searchText)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: DS.Control.height)
                .focused(isSearchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .accessibilityLabel("Search notes")

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
                .accessibilityLabel("Clear search")
                .transition(.opacity.combined(with: .scale(scale: 0.6)))
            }
        }
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity)
        .glassEffect(.control, in: .capsule)
        .animation(DS.Motion.quick(reduceMotion), value: searchText.isEmpty)
        // The field exists only while searching: it takes the focus as it appears.
        .onAppear { isSearchFocused.wrappedValue = true }
    }

    // MARK: Selecting

    private var selectionControls: some View {
        HStack(spacing: DS.Spacing.sm) {
            GlassPillButton(title: allSelected ? String(localized: "Deselect all") : String(localized: "Select all"),
                            action: onToggleSelectAll)

            Spacer(minLength: 0)

            GlassCircleButton(title: String(localized: "Delete selected notes"), systemImage: "trash",
                              role: .destructive) {
                showDeleteConfirm = true
            }
            .disabled(!canDelete)
            // Attached to the button so the popover points at it.
            .confirmationDialog(deleteTitle, isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button(deleteTitle, role: .destructive, action: onConfirmDelete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action can't be undone.")
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.bottom, DS.Spacing.xxs)
    }
}

/// Press feedback of the dock discs: a firmer squeeze than cards.
struct DockButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(DS.Motion.quick(reduceMotion), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DockButtonStyle {
    static var dock: DockButtonStyle { DockButtonStyle() }
}

/// Zoom-transition source id of the compose button (new notes grow out of it).
enum ComposeZoomSource {
    static let id = "compose"
}
