import SwiftUI

/// A labeled control pairing a typed input with a `Stepper`, both bound to the same
/// `Int` value, so either typing a number or tapping +/- keeps the other in sync.
///
/// Fields that never need negative values (`allowsNegative == false`, e.g. step size)
/// use the plain `.numberPad` keyboard. Fields that allow negatives (`allowsNegative
/// == true`, e.g. count) use `.numbersAndPunctuation` instead — it's the only stock
/// `UIKeyboardType` that exposes a minus key without switching pages, though it also
/// exposes unrelated punctuation. `sanitize(_:)` strips anything that isn't an
/// optional leading minus sign followed by digits, so the underlying value always
/// stays clean regardless of what the keyboard lets the user tap.
struct NumericInputField: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...1000
    var stepAmount: Int = 1
    var allowsNegative: Bool = false

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    /// Caps how many digits `text` can hold so it can't grow past what `Int` can
    /// parse (an all-digit string longer than ~19 characters makes `Int(_:)` return
    /// `nil`, which `recomputeValue()` would silently read as a magnitude of 0). Sized
    /// to the longest bound of `range`, so it's never smaller than a legitimate value.
    private var maxDigitCount: Int {
        String(max(abs(range.lowerBound), abs(range.upperBound))).count
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)

            Spacer()

            TextField("0", text: $text)
                .keyboardType(allowsNegative ? .numbersAndPunctuation : .numberPad)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 60)
                .valueChipStyle()
                .focused($isFocused)
                .accessibilityLabel("\(title) value")
                .onChange(of: text) { _, newValue in
                    let sanitized = sanitize(newValue)
                    if sanitized != newValue { text = sanitized }
                    recomputeValue()
                }

            Stepper("", value: $value, in: range, step: stepAmount)
                .labelsHidden()
        }
        .onAppear {
            text = String(value)
        }
        .onChange(of: value) { _, newValue in
            guard !isFocused else { return }
            text = String(newValue)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = String(value)
            }
        }
    }

    /// Reduces free-typed text to "optional single leading minus sign (only when
    /// `allowsNegative`), then up to `maxDigitCount` digits" — dropping everything
    /// else, including stray punctuation from the `.numbersAndPunctuation` keyboard
    /// and any minus sign typed anywhere but the very first position.
    private func sanitize(_ raw: String) -> String {
        var result = ""
        var digitCount = 0
        for (offset, character) in raw.enumerated() {
            if offset == 0, allowsNegative, character == "-" {
                result.append(character)
            } else if character.isNumber, digitCount < maxDigitCount {
                result.append(character)
                digitCount += 1
            }
        }
        return result
    }

    private func recomputeValue() {
        let parsed = Int(text) ?? 0
        value = min(max(parsed, range.lowerBound), range.upperBound)
    }
}

private extension View {
    /// The rounded "chip" background shared by both fields' text boxes, so Step and
    /// Count read as the same kind of control.
    func valueChipStyle() -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NumericInputFieldPreview()
}

private struct NumericInputFieldPreview: View {
    @State private var step = 5
    @State private var count = -12

    var body: some View {
        Form {
            NumericInputField(title: "Step Size", value: $step, range: Counter.stepRange)
            NumericInputField(title: "Count", value: $count, range: Counter.countRange, allowsNegative: true)
        }
    }
}
