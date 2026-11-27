import SwiftUI

/// Floating top-trailing control of the home screen, laid over the content with
/// no bar or background behind it (like the bottom dock): one glass circle opening
/// the options (sort, select), which morphs into "Cancel" while selecting.
/// The avatar and greeting live in `HomeHeader` and scroll with the content.
struct HomeTopBar: View {
    let isSelecting: Bool
    let hasNotes: Bool
    @Binding var sortOrder: NoteSortOrder
    let onBeginSelection: () -> Void
    let onEndSelection: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            GlassEffectContainer(spacing: DS.Spacing.sm) {
                trailing
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.xs)
        .animation(DS.Motion.morph(reduceMotion), value: isSelecting)
    }

    @ViewBuilder
    private var trailing: some View {
        if isSelecting {
            GlassPillButton(title: String(localized: "Cancel"), height: DS.Control.headerCircle,
                            action: onEndSelection)
                .glassEffectID("topTrailing", in: glassNamespace)
        } else if hasNotes {
            optionsMenu
                .glassEffectID("topTrailing", in: glassNamespace)
        }
    }

    /// Sort order and selection mode: secondary actions, one tap away.
    private var optionsMenu: some View {
        Menu {
            Section("Sort by") {
                Picker("Sort by", selection: $sortOrder) {
                    ForEach(NoteSortOrder.allCases) { order in
                        Label(order.label, systemImage: order.icon).tag(order)
                    }
                }
                .pickerStyle(.inline)
            }
            Button(action: onBeginSelection) {
                Label("Select notes", systemImage: "checkmark.circle")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: DS.Control.headerCircle, height: DS.Control.headerCircle)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.control, in: .circle)
        .accessibilityLabel("Options")
        .accessibilityShowsLargeContentViewer {
            Label("Options", systemImage: "ellipsis")
        }
    }
}

#Preview {
    @Previewable @State var order = NoteSortOrder.dateModified
    VStack {
        HomeTopBar(isSelecting: false, hasNotes: true, sortOrder: $order,
                   onBeginSelection: {}, onEndSelection: {})
        Spacer()
    }
}
