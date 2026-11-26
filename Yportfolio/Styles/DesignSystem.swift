import SwiftUI

// MARK: - Design tokens

/// Centralised design tokens.
///
/// Two layers:
/// - **content** (notes, text): solid surfaces on the system background (white / black);
/// - **interaction** (floating islands, compose, editor actions): Liquid Glass.
///
/// Every interactive control sits on one 52 pt grid: islands, standalone circles,
/// pills, the search field and the compose button share that height, so controls
/// line up wherever they meet.
enum DS {

    // ── Spacing (4 pt grid) ───────────────────────────────────────────
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 20
        static let xl:  CGFloat = 28
        static let xxl: CGFloat = 40
        /// Horizontal margin of every screen.
        static let screen: CGFloat = 20
    }

    // ── Controls ──────────────────────────────────────────────────────
    enum Control {
        /// Height of every floating control (island, circle, pill, search, compose).
        static let height: CGFloat = 52
        /// Inner padding of an island; its buttons are `height - 2 × islandInset`.
        static let islandInset: CGFloat = 4
        /// Gap between buttons inside an island.
        static let islandSpacing: CGFloat = 2
        /// Button diameter inside an island (44 pt: the minimum hit target).
        static var islandButton: CGFloat { height - 2 * islandInset }
        /// SF Symbol size inside circular controls.
        static let symbolSize: CGFloat = 17
        /// Small circular control living on cards (pin / selection).
        static let cardBadge: CGFloat = 32
        /// Home top row: avatar and the trailing circle share this diameter.
        static let headerCircle: CGFloat = 56
    }

    // ── Home dock (bottom floating bar) ───────────────────────────────
    enum Dock {
        /// Diameter of the two large buttons (compose, search).
        static let button: CGFloat = 84
        /// Same buttons when vertical space is scarce (iPhone landscape).
        static let compactButton: CGFloat = 56
        /// Inset of the glass capsule around them, and gap between them.
        static let inset: CGFloat = 6
        /// Diameter of the secondary circle beside the capsule.
        static let accessory: CGFloat = 48
    }

    // ── Corner radii ──────────────────────────────────────────────────
    enum Radius {
        static let card: CGFloat = 28
        static let row: CGFloat = 22
        /// Home dashboard cards and the capture card.
        static let hero: CGFloat = 32
        /// Line pills inside the featured card.
        static let pill: CGFloat = 18
    }

    // ── Typography ────────────────────────────────────────────────────
    /// SF Pro only. Personality comes from scale and weight contrast:
    /// a very large display title against compact, quiet metadata.
    enum Typography {
        /// Base size of the display titles (home + editor), scaled with Dynamic Type.
        static let displaySize: CGFloat = 40
        static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
        /// Base size of the home hero title ("Vos notes !").
        static let heroSize: CGFloat = 46

        static let sectionLabel = Font.footnote.weight(.semibold)
        static let rowTitle     = Font.headline
        static let cardTitle    = Font.title3.weight(.bold)
        static let wideTitle    = Font.headline
        static let preview      = Font.subheadline
        static let metadata     = Font.caption.weight(.medium)
        static let control      = Font.body.weight(.semibold)
    }

    // ── Surfaces ──────────────────────────────────────────────────────
    enum Surface {
        /// Screen background: white in Light Mode, black in Dark Mode.
        static let background = Color(uiColor: .systemBackground)
        /// Neutral raised surface (list cards, chips, badges).
        static let raised = Color(uiColor: .secondarySystemBackground)
        /// Surface nested on a raised card (white in Light Mode, a lighter grey in Dark Mode).
        static let inset = Color(uiColor: .tertiarySystemBackground)
        /// Hairline outline of unselected pills and quiet circles.
        static let hairline = Color.primary.opacity(0.14)

        /// Soft, note-specific card colour: a pastel in Light Mode,
        /// a deep tone in Dark Mode. Text on top stays `.primary`.
        static func tint(_ accent: Color, _ scheme: ColorScheme) -> Color {
            accent.opacity(scheme == .dark ? 0.26 : 0.15)
        }
    }

    // ── Motion ────────────────────────────────────────────────────────
    enum Motion {
        /// Default state change: short, critically damped (no bounce).
        /// `nil` with Reduce Motion, so content changes without travelling.
        static func standard(_ reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .smooth(duration: 0.35)
        }

        /// Slightly livelier spring for controls that morph (islands, chips).
        static func morph(_ reduceMotion: Bool) -> Animation {
            reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.4, bounce: 0.15)
        }

        /// Small, immediate feedback (selection, press).
        static func quick(_ reduceMotion: Bool) -> Animation {
            reduceMotion ? .linear(duration: 0.1) : .snappy(duration: 0.22)
        }
    }
}
