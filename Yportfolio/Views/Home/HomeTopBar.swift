import SwiftUI

/// Floating top bar of the home screen (a `safeAreaBar`, so content scrolls
/// under it with the system scroll-edge effect).
///
/// Leading: greeting and date; once the big title has scrolled away, a compact
/// "Mes notes"; in selection mode, the selection count.
/// Trailing: one glass island (layout switch + select), or "Annuler" while selecting.
struct HomeTopBar: View {
    let isSelecting: Bool
    let selectionSummary: String
    let isCollapsed: Bool
    let hasNotes: Bool
    let viewStyle: NoteViewStyle
    let onToggleViewStyle: () -> Void
    let onBeginSelection: () -> Void
    let onEndSelection: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.sm) {
            leading
                .frame(maxWidth: .infinity, alignment: .leading)

            GlassEffectContainer(spacing: DS.Spacing.sm) {
                trailing
            }
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.vertical, DS.Spacing.xs)
        .animation(DS.Motion.morph(reduceMotion), value: isSelecting)
        .animation(DS.Motion.standard(reduceMotion), value: isCollapsed)
    }

    // MARK: Leading

    @ViewBuilder
    private var leading: some View {
        Group {
            if isSelecting {
                Text(selectionSummary)
                    .font(.headline)
                    .contentTransition(.numericText())
                    .id("selection")
            } else if isCollapsed {
                Text("Mes notes")
                    .font(.headline)
                    .id("compact")
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(Self.greeting)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .id("greeting")
            }
        }
        .transition(.opacity.combined(with: .offset(y: reduceMotion ? 0 : 6)))
        .lineLimit(1)
    }

    // MARK: Trailing

    @ViewBuilder
    private var trailing: some View {
        if isSelecting {
            GlassPillButton(title: "Annuler", action: onEndSelection)
                .glassEffectID("topTrailing", in: glassNamespace)
        } else if hasNotes {
            ControlIsland {
                Button(action: onToggleViewStyle) {
                    Label(viewStyle.switchLabel, systemImage: viewStyle.switchIcon)
                        .contentTransition(.symbolEffect(.replace))
                }
                Button(action: onBeginSelection) {
                    Label("Sélectionner des notes", systemImage: "checkmark.circle")
                }
            }
            .glassEffectID("topTrailing", in: glassNamespace)
        }
    }

    /// Time-of-day greeting.
    private static var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return "Bonjour"
        case 12..<18: return "Bon après-midi"
        default:      return "Bonsoir"
        }
    }
}
