import SwiftUI

/// Pin control living in a card's corner: visible, tappable (no hidden gesture),
/// and doubling as the pinned-state indicator.
struct PinToggle: View {
    let isPinned: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isPinned ? DS.Surface.background : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: DS.Control.cardBadge, height: DS.Control.cardBadge)
                .background {
                    Circle().fill(isPinned ? AnyShapeStyle(Color.primary)
                                           : AnyShapeStyle(DS.Surface.background.opacity(0.7)))
                }
                // 44 pt hit target around the 32 pt visual.
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isPinned ? "Désépingler" : "Épingler")
    }
}

/// Selection state shown in the same corner as `PinToggle` while selecting.
/// Decorative for VoiceOver: the card itself carries the `.isSelected` trait.
struct SelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .opacity(isSelected ? 1 : 0)
            .frame(width: DS.Control.cardBadge, height: DS.Control.cardBadge)
            .background {
                Circle().fill(isSelected ? AnyShapeStyle(Color.accentColor)
                                         : AnyShapeStyle(DS.Surface.background.opacity(0.7)))
            }
            .overlay {
                Circle().strokeBorder(Color.secondary.opacity(isSelected ? 0 : 0.6), lineWidth: 1.5)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        PinToggle(isPinned: false) {}
        PinToggle(isPinned: true) {}
        SelectionIndicator(isSelected: false)
        SelectionIndicator(isSelected: true)
    }
    .padding()
    .background(DS.Surface.tint(.orange, .light))
}
