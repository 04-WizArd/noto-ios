import SwiftUI

// MARK: - Glass styles

extension Glass {
    /// Neutral interactive glass for floating controls.
    static var control: Glass { .regular.interactive() }
    /// The one prominent action of a screen: glass tinted with the label colour
    /// (near-black in Light Mode, near-white in Dark Mode), like a solid key.
    static var prominent: Glass { .regular.tint(.primary).interactive() }
}

// MARK: - Island

/// A floating group of circular icon buttons on one glass capsule.
///
/// Geometry is fixed by `DS.Control`: 52 pt tall, 4 pt inset, 44 pt buttons,
/// 2 pt gaps, so every island, circle and pill in the app has the same height
/// and buttons are optically centred in identical square frames.
struct ControlIsland<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: DS.Control.islandSpacing) {
            content
        }
        .buttonStyle(.islandIcon)
        .labelStyle(.iconOnly)
        .padding(DS.Control.islandInset)
        .glassEffect(.control, in: .capsule)
    }
}

/// Icon button inside an island: fixed square frame, centred symbol,
/// press feedback, dimmed when disabled.
struct IslandIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DS.Control.symbolSize, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: DS.Control.islandButton, height: DS.Control.islandButton)
            .contentShape(Circle())
            .background {
                Circle()
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : 0))
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .opacity(isEnabled ? 1 : 0.35)
            .animation(DS.Motion.quick(reduceMotion), value: configuration.isPressed)
            // Floating controls keep their size (like system bars); long-press shows
            // the Large Content Viewer at accessibility text sizes.
            .accessibilityShowsLargeContentViewer()
    }
}

extension ButtonStyle where Self == IslandIconButtonStyle {
    static var islandIcon: IslandIconButtonStyle { IslandIconButtonStyle() }
}

// MARK: - Standalone controls

/// A single circular glass control (back, close, delete…), 52 pt like an island by default.
struct GlassCircleButton: View {
    let title: String
    let systemImage: String
    var prominent = false
    var role: ButtonRole? = nil
    var size: CGFloat = DS.Control.height
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemImage)
                .font(.system(size: DS.Control.symbolSize + (prominent ? 3 : 0), weight: .semibold))
                .foregroundStyle(prominent ? DS.Surface.background : (role == .destructive ? Color.red : Color.primary))
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(prominent ? .prominent : .control, in: .circle)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(title)
        .accessibilityShowsLargeContentViewer {
            Label(title, systemImage: systemImage)
        }
    }
}

/// A text pill on glass (e.g. "Done", "Cancel", "Select all"), 52 pt tall by default.
struct GlassPillButton: View {
    let title: String
    var prominent = false
    var height: CGFloat = DS.Control.height
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Typography.control)
                .foregroundStyle(prominent ? DS.Surface.background : Color.primary)
                .lineLimit(1)
                .padding(.horizontal, 22)
                .frame(minHeight: height)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(prominent ? .prominent : .control, in: .capsule)
    }
}

// MARK: - Previews

#Preview {
    VStack(spacing: 24) {
        HStack {
            GlassCircleButton(title: "Back", systemImage: "chevron.left") {}
            Spacer()
            ControlIsland {
                Button("Pin", systemImage: "bookmark") {}
                Button("Delete", systemImage: "trash") {}
            }
        }
        HStack {
            GlassPillButton(title: "Select all") {}
            Spacer()
            GlassPillButton(title: "Done", prominent: true) {}
            GlassCircleButton(title: "New note", systemImage: "plus", prominent: true) {}
        }
    }
    .padding()
}
