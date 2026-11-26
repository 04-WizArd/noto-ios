import SwiftUI

/// Press feedback for card-like buttons: a slight scale-down that follows the finger.
/// A `ButtonStyle` (not a drag gesture) so it cooperates with scrolling, swipe
/// actions and context menus.
struct CardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(DS.Motion.quick(reduceMotion), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}
