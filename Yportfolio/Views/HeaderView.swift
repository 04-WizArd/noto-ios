//
//  HeaderView.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 23/05/2026.
//

import SwiftUI

/// Reusable section header: large rounded title + optional count badge.
struct SectionHeaderView: View {
    let title: String
    var count: Int? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.xs) {
            Text(title)
                .font(DS.Typography.title2())
                .foregroundStyle(.primary)

            if let count {
                Text("\(count)")
                    .font(DS.Typography.caption().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(DS.Animation.interactive, value: count)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading) {
        SectionHeaderView(title: "Toutes les notes", count: 12)
        SectionHeaderView(title: "Récentes")
    }
    .padding()
}
