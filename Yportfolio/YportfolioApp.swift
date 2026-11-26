//
//  YportfolioApp.swift
//  Yportfolio
//
//  Created by Jordi Jordi on 21/05/2026.
//

import SwiftUI
import SwiftData

@main
struct YportfolioApp: App {

    // MARK: - Appearance

    init() {
        configureGlobalAppearance()
    }

    // MARK: - SwiftData container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - UIKit global appearance

    private func configureGlobalAppearance() {

        // ── Navigation Bar ────────────────────────────────────────────
        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.shadowColor = .clear   // no hairline under nav bar

        // Large title: system default weight (no custom font — matches Notes)
        nav.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        nav.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        UINavigationBar.appearance().standardAppearance   = nav
        UINavigationBar.appearance().compactAppearance    = nav

        // Scroll edge: transparent so large title blends into content
        let transparent = UINavigationBarAppearance()
        transparent.configureWithTransparentBackground()
        transparent.largeTitleTextAttributes = nav.largeTitleTextAttributes
        transparent.titleTextAttributes      = nav.titleTextAttributes
        UINavigationBar.appearance().scrollEdgeAppearance = transparent

        // ── Toolbar (bottom bar) ──────────────────────────────────────
        let toolbar = UIToolbarAppearance()
        toolbar.configureWithDefaultBackground()
        toolbar.shadowColor = .clear
        UIToolbar.appearance().standardAppearance   = toolbar
        UIToolbar.appearance().compactAppearance    = toolbar
        UIToolbar.appearance().scrollEdgeAppearance = toolbar

        // ── List / TableView ──────────────────────────────────────────
        UITableView.appearance().backgroundColor = .clear
    }
}
