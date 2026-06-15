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

    // MARK: - Init (global UIKit appearance)

    init() {
        configureGlobalAppearance()
    }

    // MARK: - SwiftData container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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

    // MARK: - Appearance

    /// Configures UIKit-level appearance so the navigation bar stays
    /// transparent / blurred, matching the BackgroundView beneath it.
    private func configureGlobalAppearance() {
        // Navigation bar — transparent by default, material applied via SwiftUI
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.shadowColor = .clear

        // Large title font: SF Rounded Bold to match DS.Typography
        let largeTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navAppearance.largeTitleTextAttributes = largeTitleAttrs

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.titleTextAttributes = titleAttrs

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance

        // Remove list separators globally (cleaner look in any future lists)
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .clear
    }
}
