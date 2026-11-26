import SwiftUI

/// Home screen identity block, scrolling with the content:
/// a large display title with the note count, then the sort chips.
/// (The greeting / date line lives in `HomeTopBar`, which stays on screen.)
struct HomeHeader: View {
    let count: Int
    @Binding var sortOrder: NoteSortOrder
    var showsSort = true

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = DS.Typography.displaySize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var chipNamespace

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.sm) {
                Text("Mes notes")
                    .font(DS.Typography.display(titleSize))
                    .tracking(-0.8)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                if count > 0 {
                    Text(count, format: .number)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText(value: Double(count)))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DS.Surface.raised, in: Capsule())
                        .accessibilityLabel("\(count) note\(count == 1 ? "" : "s")")
                }
            }
            .animation(DS.Motion.quick(reduceMotion), value: count)

            if showsSort {
                sortChips
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Sort options as chips (visible, one tap) rather than buried in a menu.
    /// The selected chip's fill slides between chips.
    private var sortChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(NoteSortOrder.allCases) { order in
                    let isSelected = order == sortOrder
                    Button {
                        withAnimation(DS.Motion.morph(reduceMotion)) { sortOrder = order }
                    } label: {
                        Text(order.shortLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? DS.Surface.background : Color.primary)
                            .padding(.horizontal, DS.Spacing.md)
                            .frame(minHeight: 36)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(Color.primary)
                                        .matchedGeometryEffect(id: "selectedChip", in: chipNamespace)
                                } else {
                                    Capsule().strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                                }
                            }
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Trier par \(order.label.lowercased())")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}

#Preview {
    @Previewable @State var order = NoteSortOrder.dateModified
    HomeHeader(count: 12, sortOrder: $order)
        .padding()
}
