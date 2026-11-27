import SwiftUI

/// Quiet editorial section label ("OTHER NOTES  2"): structure without competing
/// with the display title or the cards.
struct SectionLabel: View {
    let title: String
    var systemImage: String? = nil
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
            }
            Text(title.uppercased())
                .tracking(0.8)
            Text(count, format: .number)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .contentTransition(.numericText(value: Double(count)))
        }
        .font(DS.Typography.sectionLabel)
        .foregroundStyle(Color.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(title), \(count) notes"))
        .accessibilityAddTraits(.isHeader)
    }
}
