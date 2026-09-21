import SwiftUI

/// A labeled control pairing a typed input with a `Stepper`, both bound to the same
/// `Int` value, so either typing a number or tapping +/- keeps the other in sync.
///
/// Fields that allow negative values (`allowsNegative == true`, e.g. count) get a
/// small sign-toggle button next to the field — the plain `.numberPad` keyboard has
/// no minus key at all, and `.numbersAndPunctuation` (the alternative) shows a page
/// of unrelated punctuation for the sake of one key, so a dedicated toggle is the
/// simplest clean way to enter negative values.
struct NumericInputField: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...1000
    var stepAmount: Int = 1
    var allowsNegative: Bool = false

    @State private var digitsText: String = ""
    @State private var isNegative: Bool = false
    @FocusState private var isFocused: Bool

    /// Caps how many digits `digitsText` can hold so it can't grow past what `Int`
    /// can parse (an all-digit string longer than ~19 characters makes `Int(_:)`
    /// return `nil`, which `recomputeValue()` would silently read as a magnitude of
    /// 0). Sized to the longest bound of `range`.
    private var maxDigitCount: Int {
        String(max(abs(range.lowerBound), abs(range.upperBound))).count
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(title)

            Spacer()

            if allowsNegative {
                Button {
                    isNegative.toggle()
                    recomputeValue()
                } label: {
                    Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(isNegative ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isNegative ? "Negative" : "Positive")
                .accessibilityHint("Double tap to toggle sign")
            }

            TextField("0", text: $digitsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 44)
                .valueChipStyle()
                .focused($isFocused)
                .accessibilityLabel("\(title) value")
                .onChange(of: digitsText) { _, newValue in
                    var filtered = newValue.filter(\.isNumber)
                    if filtered.count > maxDigitCount {
                        filtered = String(filtered.prefix(maxDigitCount))
                    }
                    if filtered != newValue { digitsText = filtered }
                    recomputeValue()
                }

            Stepper("", value: $value, in: range, step: stepAmount)
                .labelsHidden()
        }
        .onAppear {
            isNegative = value < 0
            digitsText = String(abs(value))
        }
        .onChange(of: value) { _, newValue in
            guard !isFocused else { return }
            isNegative = newValue < 0
            digitsText = String(abs(newValue))
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                digitsText = String(abs(value))
                isNegative = value < 0
            }
        }
    }

    private func recomputeValue() {
        let magnitude = Int(digitsText) ?? 0
        let signed = (allowsNegative && isNegative) ? -magnitude : magnitude
        value = min(max(signed, range.lowerBound), range.upperBound)
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
