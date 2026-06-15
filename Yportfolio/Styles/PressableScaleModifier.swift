//
//  PressableScaleModifier.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 23/05/2026.
//

import SwiftUI

/// Applies a subtle press-down scale to any view that isn't a Button.
/// Use `.pressableScale()` on tappable cards or custom tap targets.
struct PressableScale: ViewModifier {
    @GestureState private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.90 : 1.0)
            .animation(
                .spring(response: 0.28, dampingFraction: 0.72),
                value: isPressed
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

extension View {
    func pressableScale() -> some View {
        self.modifier(PressableScale())
    }
}

#Preview {
    Text("Tap me")
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .pressableScale()
}
