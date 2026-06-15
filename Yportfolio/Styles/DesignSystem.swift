//
//  DesignSystem.swift
//  Yportfolio
//
//  Design tokens centralisés — modifier ici pour propager partout.
//

import SwiftUI

// MARK: - Spacing

enum DS {

    // ── Spacing scale (inspired by 4pt grid) ──────────────────────────
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs:  CGFloat = 8
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 20
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // ── Corner radii ──────────────────────────────────────────────────
    enum Radius {
        static let sm:  CGFloat = 12
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 20
        static let xl:  CGFloat = 28
    }

    // ── Shadows ───────────────────────────────────────────────────────
    enum Shadow {
        struct Config {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static func card(accent: Color, scheme: ColorScheme) -> Config {
            Config(
                color: accent.opacity(scheme == .dark ? 0.30 : 0.18),
                radius: 16, x: 0, y: 8
            )
        }

        static func sheet(accent: Color, scheme: ColorScheme) -> Config {
            Config(
                color: accent.opacity(scheme == .dark ? 0.45 : 0.22),
                radius: 40, x: 0, y: -8
            )
        }
    }

    // ── Animation presets ─────────────────────────────────────────────
    enum Animation {
        /// Standard interactive spring — buttons, cards
        static let interactive = SwiftUI.Animation.spring(
            response: 0.28, dampingFraction: 0.72
        )
        /// Overlay / sheet presentation
        static let overlay = SwiftUI.Animation.spring(
            response: 0.40, dampingFraction: 0.85
        )
    }

    // ── Typography ────────────────────────────────────────────────────
    enum Typography {
        static func largeTitle()  -> Font { .system(.largeTitle,  design: .rounded).weight(.bold) }
        static func title()       -> Font { .system(.title,       design: .rounded).weight(.bold) }
        static func title2()      -> Font { .system(.title2,      design: .rounded).weight(.bold) }
        static func headline()    -> Font { .system(.headline,    design: .rounded) }
        static func subheadline() -> Font { .system(.subheadline, design: .rounded).weight(.semibold) }
        static func body()        -> Font { .system(.body) }
        static func callout()     -> Font { .system(.callout) }
        static func footnote()    -> Font { .system(.footnote) }
        static func caption()     -> Font { .system(.caption) }
        static func caption2()    -> Font { .system(.caption2) }
    }

    // ── Materials ─────────────────────────────────────────────────────
    enum Material {
        static let card:    SwiftUI.Material = .ultraThinMaterial
        static let overlay: SwiftUI.Material = .ultraThickMaterial
        static let toolbar: SwiftUI.Material = .ultraThinMaterial
    }
}

// MARK: - View Extensions (convenience)

extension View {
    /// Applies a card shadow using DS tokens.
    func cardShadow(accent: Color, scheme: ColorScheme) -> some View {
        let s = DS.Shadow.card(accent: accent, scheme: scheme)
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Applies a sheet/overlay shadow using DS tokens.
    func sheetShadow(accent: Color, scheme: ColorScheme) -> some View {
        let s = DS.Shadow.sheet(accent: accent, scheme: scheme)
        return self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}
