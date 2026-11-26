import SwiftUI

/// Floating top row of the home screen (a `safeAreaBar`, so content scrolls
/// under it with the system scroll-edge effect).
///
/// Leading: avatar, greeting and date (the date gives way to "Vos notes" once the
/// hero title has scrolled away); in selection mode, the selection count.
/// Trailing: one glass circle opening the options (sort, select), which morphs
/// into "Annuler" while selecting.
struct HomeTopBar: View {
    let isSelecting: Bool
    let selectionSummary: String
    let isCollapsed: Bool
    let hasNotes: Bool
    @Binding var sortOrder: NoteSortOrder
    let onBeginSelection: () -> Void
    let onEndSelection: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var glassNamespace

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.sm) {
            leading
                .frame(maxWidth: .infinity, alignment: .leading)

            GlassEffectContainer(spacing: DS.Spacing.sm) {
                trailing
            }
        }
        .frame(minHeight: DS.Control.headerCircle)
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, DS.Spacing.xxs)
        .padding(.bottom, DS.Spacing.xs)
        .animation(DS.Motion.morph(reduceMotion), value: isSelecting)
        .animation(DS.Motion.standard(reduceMotion), value: isCollapsed)
    }

    // MARK: Leading

    @ViewBuilder
    private var leading: some View {
        if isSelecting {
            Text(selectionSummary)
                .font(.title3.weight(.semibold))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .transition(.opacity)
        } else {
            HStack(spacing: DS.Spacing.sm) {
                HomeAvatar()
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(Self.greeting) 👋")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    ZStack(alignment: .leading) {
                        if isCollapsed {
                            Text("Vos notes")
                                .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : 6)))
                        } else {
                            Text(Self.today)
                                .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : -6)))
                        }
                    }
                    .font(.title2)
                    .foregroundStyle(.primary)
                }
                // Wraps rather than truncating the date at accessibility sizes.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.75)
                .accessibilityElement(children: .combine)
            }
            .transition(.opacity)
        }
    }

    // MARK: Trailing

    @ViewBuilder
    private var trailing: some View {
        if isSelecting {
            GlassPillButton(title: "Annuler", action: onEndSelection)
                .glassEffectID("topTrailing", in: glassNamespace)
        } else if hasNotes {
            optionsMenu
                .glassEffectID("topTrailing", in: glassNamespace)
        }
    }

    /// Sort order and selection mode: secondary actions, one tap away.
    private var optionsMenu: some View {
        Menu {
            Section("Trier par") {
                Picker("Trier par", selection: $sortOrder) {
                    ForEach(NoteSortOrder.allCases) { order in
                        Label(order.label, systemImage: order.icon).tag(order)
                    }
                }
                .pickerStyle(.inline)
            }
            Button(action: onBeginSelection) {
                Label("Sélectionner des notes", systemImage: "checkmark.circle")
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

    // MARK: Text

    /// Time-of-day greeting.
    private static var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Bonjour"
        case 12..<18: return "Bon après-midi"
        default:      return "Bonsoir"
        }
    }

    /// "Jeudi 26 novembre" (locale format, first letter capitalised).
    private static var today: String {
        let text = Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
        return text.prefix(1).capitalized + text.dropFirst()
    }
}

/// Decorative identity disc of the home header. The app has no accounts, so it
/// shows a generic silhouette on a soft gradient instead of a photo.
struct HomeAvatar: View {
    var body: some View {
        Circle()
            .fill(
                LinearGradient(colors: [Color.indigo.mix(with: .white, by: 0.25), .purple, .pink.mix(with: .orange, by: 0.3)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(alignment: .bottom) {
                Image(systemName: "person.fill")
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .offset(y: 7)
            }
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1)
            }
            .frame(width: DS.Control.headerCircle, height: DS.Control.headerCircle)
            .accessibilityHidden(true)
    }
}

#Preview {
    @Previewable @State var order = NoteSortOrder.dateModified
    VStack {
        HomeTopBar(isSelecting: false, selectionSummary: "", isCollapsed: false, hasNotes: true,
                   sortOrder: $order, onBeginSelection: {}, onEndSelection: {})
        Spacer()
    }
}
