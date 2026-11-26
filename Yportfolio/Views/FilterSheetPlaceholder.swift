import SwiftUI

/// Placeholder for the future filters sheet. Not reachable yet: its menu entry
/// (`ContentView.filterMenuItem`) is hidden until filters are implemented.
struct FilterSheetPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Filtres",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Cette fonctionnalité sera disponible prochainement.")
            )
            .navigationTitle("Filtrer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
