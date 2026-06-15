//
//  PressableButtorStyle.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 23/05/2026.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(
                .spring(response: 0.28, dampingFraction: 0.72, blendDuration: 0),
                value: configuration.isPressed
            )
    }
}

#Preview {
    Button("Test") {}
        .buttonStyle(PressableButtonStyle())
}
