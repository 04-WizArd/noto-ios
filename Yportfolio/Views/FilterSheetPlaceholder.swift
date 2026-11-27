import SwiftUI

/// Placeholder for the future filters sheet. Not reachable yet: its menu entry
/// (`ContentView.filterMenuItem`) is hidden until filters are implemented.
struct FilterSheetPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Filters",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("This feature will be available soon.")
            )
            .navigationTitle("Filter")
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
