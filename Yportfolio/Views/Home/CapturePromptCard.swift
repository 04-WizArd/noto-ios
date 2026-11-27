import SwiftUI

/// Quick capture: "What would you like to note?" — type a line and send it to save it
/// as a new note without leaving the home screen.
struct CapturePromptCard: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    @ScaledMetric(relativeTo: .body) private var sendSize: CGFloat = 46

    private var isBlank: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            TextField("What would you like to note?", text: $text)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .focused(isFocused)
                .submitLabel(.send)
                .onSubmit(send)
                .frame(maxWidth: .infinity, minHeight: sendSize)

            Button(action: send) {
                Image(systemName: "paperplane")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isBlank ? Color.primary : DS.Surface.background)
                    .frame(width: sendSize, height: sendSize)
                    .background {
                        Circle().fill(isBlank ? AnyShapeStyle(DS.Surface.inset) : AnyShapeStyle(Color.primary))
                    }
                    .overlay {
                        Circle().strokeBorder(DS.Surface.hairline, lineWidth: 1)
                            .opacity(isBlank ? 1 : 0)
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.card)
            .accessibilityLabel(isBlank ? String(localized: "Write a quick note") : String(localized: "Save note"))
        }
        .padding(.leading, 22)
        .padding(.trailing, 13)
        .padding(.vertical, 13)
        .background(DS.Surface.raised, in: RoundedRectangle(cornerRadius: DS.Radius.hero, style: .continuous))
        .animation(.snappy(duration: 0.2), value: isBlank)
    }

    /// Saves the text; with nothing typed yet, the button simply starts typing.
    private func send() {
        if isBlank {
            isFocused.wrappedValue = true
        } else {
            onSubmit()
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var focused: Bool
    CapturePromptCard(text: $text, isFocused: $focused) {}
        .padding()
}
