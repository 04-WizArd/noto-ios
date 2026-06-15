//
//  BackgroundView.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 23/05/2026.
//

import SwiftUI

struct BackgroundView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            // ── Base gradient ─────────────────────────────────────────────
            LinearGradient(
                colors: baseColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // ── Radial accent bloom (top-left) ────────────────────────────
            RadialGradient(
                colors: [accentBloom, .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 380
            )
            .blendMode(scheme == .dark ? .plusLighter : .normal)
            .opacity(scheme == .dark ? 0.35 : 0.20)

            // ── Subtle bottom warmth ──────────────────────────────────────
            RadialGradient(
                colors: [Color.indigo.opacity(0.12), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 300
            )
            .blendMode(.normal)
        }
        .ignoresSafeArea()
    }

    // MARK: - Computed colors

    private var baseColors: [Color] {
        scheme == .dark
            ? [Color(hue: 0.64, saturation: 0.18, brightness: 0.08),
               Color(hue: 0.67, saturation: 0.20, brightness: 0.11)]
            : [Color(hue: 0.60, saturation: 0.06, brightness: 0.98),
               Color(hue: 0.63, saturation: 0.08, brightness: 0.96)]
    }

    private var accentBloom: Color {
        scheme == .dark
            ? Color.purple.opacity(0.30)
            : Color.blue.opacity(0.12)
    }
}

// MARK: - Preview

#Preview("Light") {
    BackgroundView()
        .environment(\.colorScheme, .light)
}

#Preview("Dark") {
    BackgroundView()
        .environment(\.colorScheme, .dark)
}
