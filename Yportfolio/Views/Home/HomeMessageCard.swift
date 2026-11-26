import SwiftUI

/// Large calm card used for the empty states (no notes, no search result).
struct HomeMessageCard<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 72, height: 72)
                .background(DS.Surface.background, in: Circle())
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.xxs) {
                Text(title)
                    .font(.title3.weight(.bold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            actions
        }
        .padding(.vertical, DS.Spacing.xxl)
        .padding(.horizontal, DS.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(DS.Surface.raised, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

extension HomeMessageCard where Actions == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.init(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}
