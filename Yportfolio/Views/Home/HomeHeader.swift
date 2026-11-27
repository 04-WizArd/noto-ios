import SwiftUI

/// Home hero block, scrolling with the content: avatar and greeting (or the
/// selection count while selecting), the large "Your notes!" title, then the
/// filter chips ("All" with the note count, "Pinned", "Recent").
/// The identity row keeps room on its right for the floating `HomeTopBar` control.
struct HomeHeader: View {
    let totalCount: Int
    @Binding var filter: NoteFilter
    var showsFilters = true
    /// Shown in place of the greeting while selecting.
    var selectionSummary: String? = nil

    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = DS.Typography.heroSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            identityRow

            // The French translation carries a narrow no-break space before "!".
            Text("Your notes!")
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

    // MARK: Identity row

    private var identityRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            if let selectionSummary {
                Text(selectionSummary)
                    .font(.title3.weight(.semibold))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                HomeAvatar()
                VStack(alignment: .leading, spacing: 1) {
                    Text(Self.greeting + " 👋")
                        .font(.subheadline.weight(.medium))
                    // Locale-aware: "vendredi 27 novembre" / "Friday, November 27".
                    Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.title2)
                }
                .foregroundStyle(.primary)
                // Wraps rather than truncating the date at accessibility sizes.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .minimumScaleFactor(0.75)
                .accessibilityElement(children: .combine)
            }
            // Room for the floating options circle laid over this row.
            Spacer(minLength: DS.Control.headerCircle + DS.Spacing.sm)
        }
        .frame(minHeight: DS.Control.headerCircle)
    }

    /// Time-of-day greeting.
    private static var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12:  return String(localized: "Good morning")
        case 12..<18: return String(localized: "Good afternoon")
        default:      return String(localized: "Good evening")
        }
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
                    // "All" + its count never truncates; the others give way.
                    .fixedSize(horizontal: option == .all, vertical: false)
            }
        }
    }

    /// "All" hugs its content; the other chips share the remaining width.
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
        .accessibilityLabel(option == .all ? String(localized: "\(option.title), \(totalCount) notes") : option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var filter = NoteFilter.all
    HomeHeader(totalCount: 23, filter: $filter)
        .padding()
}
