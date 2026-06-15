//
//  NoteDetailOverlay.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 23/05/2026.
//

import SwiftUI

struct NoteDetailOverlay: View {
    let note: Note
    let namespace: Namespace.ID
    let onClose: () -> Void

    @Environment(\.colorScheme) private var scheme

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            scrim
            sheetPanel
        }
    }

    // MARK: - Scrim

    private var scrim: some View {
        Color.black
            .opacity(scheme == .dark ? 0.55 : 0.30)
            .ignoresSafeArea()
            .onTapGesture { onClose() }
    }

    // MARK: - Sheet panel

    private var sheetPanel: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()
                .opacity(0.12)
                .padding(.horizontal, DS.Spacing.xl)

            bodySection
        }
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
        .sheetShadow(accent: note.accent, scheme: scheme)
        .padding(.horizontal, DS.Spacing.md)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Header section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag handle
            dragHandle

            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    dateBadge
                    titleText
                }
                Spacer(minLength: DS.Spacing.md)
                closeButton
            }
        }
        .padding(.horizontal, DS.Spacing.xl)
        .padding(.bottom, DS.Spacing.lg)
    }

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.primary.opacity(0.18))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.lg)
    }

    private var dateBadge: some View {
        HStack(spacing: DS.Spacing.xxs + 2) {
            Circle()
                .fill(note.accent.gradient)
                .frame(width: 8, height: 8)
            Text(note.formattedDate)
                .font(DS.Typography.caption())
                .foregroundStyle(.tertiary)
        }
    }

    private var titleText: some View {
        Text(note.title.isEmpty ? "Sans titre" : note.title)
            .font(DS.Typography.title2())
            .foregroundStyle(.primary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(Color.primary.opacity(0.08), in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.top, DS.Spacing.xxs)
    }

    // MARK: - Body / scroll content

    private var bodySection: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                if !note.snippet.isEmpty {
                    Text(note.snippet)
                        .font(DS.Typography.body().weight(.medium))
                        .foregroundStyle(.primary)
                }

                Text(note.lorem)
                    .font(DS.Typography.body())
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.xl)
            .padding(.top, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xxxl)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.45)
    }

    // MARK: - Panel background

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(DS.Material.overlay)
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .fill(note.accent.opacity(scheme == .dark ? 0.08 : 0.04))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
    }
    .overlay {
        NoteDetailOverlay(
            note: Note.sample.first!,
            namespace: Namespace().wrappedValue
        ) {}
    }
}
