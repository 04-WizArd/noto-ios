import SwiftUI

/// Home hero block, scrolling with the content: the large "Vos notes !" title,
/// then the filter chips ("Toutes" with the note count, "Épinglées", "Récentes").
/// (Avatar and greeting live in `HomeTopBar`, which stays on screen.)
struct HomeHeader: View {
    let totalCount: Int
    @Binding var filter: NoteFilter
    var showsFilters = true

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = DS.Typography.heroSize

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            // Narrow no-break space before "!" (French typography).
            Text("Vos notes\u{202F}!")
                .font(DS.Typography.display(titleSize))
                .tracking(-1)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)

            if showsFilters {
                FilterChips(filter: $filter, totalCount: totalCount)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Three pill filters spanning the content width. The selected pill sits on one
/// piece of Liquid Glass that slides from chip to chip; the others are hairline outlines.
struct FilterChips: View {
    @Binding var filter: NoteFilter
    let totalCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        // One row filling the width when it fits; scrolls horizontally at large text sizes.
        ViewThatFits(in: .horizontal) {
            chips(stretch: true)
            ScrollView(.horizontal) {
                chips(stretch: false)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }

    private func chips(stretch: Bool) -> some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(NoteFilter.allCases) { option in
                chip(option)
                    .frame(maxWidth: stretch && option != .all ? .infinity : nil)
                    // "Toutes" + its count never truncates; the others give way.
                    .fixedSize(horizontal: option == .all, vertical: false)
            }
        }
    }

    /// "Toutes" hugs its content; the other chips share the remaining width.
    private func stretchesLabel(_ option: NoteFilter) -> Bool { option != .all }

    private func chip(_ option: NoteFilter) -> some View {
        let isSelected = option == filter
        return Button {
            withAnimation(DS.Motion.morph(reduceMotion)) { filter = option }
        } label: {
            HStack(spacing: DS.Spacing.xs) {
                Text(option.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                if option == .all {
                    Text(totalCount, format: .number)
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.numericText(value: Double(totalCount)))
                        .frame(minWidth: 26, minHeight: 26)
                        .padding(.horizontal, totalCount > 99 ? 4 : 0)
                        .background(Color.accentColor.opacity(0.16), in: Capsule())
                }
            }
            .lineLimit(1)
            .padding(.horizontal, DS.Spacing.md)
            .frame(maxWidth: stretchesLabel(option) ? .infinity : nil, minHeight: 48)
            .contentShape(Capsule())
            .background {
                if isSelected {
                    Capsule()
                        .fill(.clear)
                        // Neutral tint: on a plain white / black background, untinted
                        // glass is almost invisible and the selection would not read.
                        .glassEffect(.regular.tint(Color.primary.opacity(0.1)), in: .capsule)
                        .matchedGeometryEffect(id: "selectedFilter", in: glassNamespace)
                } else {
                    Capsule().strokeBorder(DS.Surface.hairline, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.card)
        .accessibilityLabel(option == .all ? "\(option.title), \(totalCount) note\(totalCount == 1 ? "" : "s")" : option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var filter = NoteFilter.all
    HomeHeader(totalCount: 23, filter: $filter)
        .padding()
}
