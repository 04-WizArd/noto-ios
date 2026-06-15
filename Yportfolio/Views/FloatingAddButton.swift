//
//  FloatingAddButton.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 23/05/2026.
//

import SwiftUI

struct FloatingAddButton: View {
    let namespace: Namespace.ID
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var isAnimating = false

    // MARK: - Body

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isAnimating = true
            }
            // Reset after a short delay so next tap re-triggers
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
            action()
        } label: {
            ZStack {
                // Frosted glass disc
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.white.opacity(scheme == .dark ? 0.12 : 0.45),
                                lineWidth: 0.6
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(scheme == .dark ? 0.45 : 0.18),
                        radius: 12, x: 0, y: 6
                    )

                // Plus icon with subtle rotation on tap
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .rotationEffect(.degrees(isAnimating ? 90 : 0))
            }
            .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Ajouter une note")
    }
}

// MARK: - Preview

#Preview {
    FloatingAddButton(namespace: Namespace().wrappedValue) {}
        .padding()
}
