import SwiftUI

/// Persistable accent colour of a note (stored as its raw `String`).
enum NoteAccent: String, CaseIterable, Codable {
    case blue, green, orange, indigo, pink, teal, purple, mint

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .green:  return .green
        case .orange: return .orange
        case .indigo: return .indigo
        case .pink:   return .pink
        case .teal:   return .teal
        case .purple: return .purple
        case .mint:   return .mint
        }
    }

    /// Accent picked for newly created notes.
    static func random() -> NoteAccent {
        [.indigo, .pink, .teal, .purple, .orange, .blue, .mint].randomElement() ?? .blue
    }
}
