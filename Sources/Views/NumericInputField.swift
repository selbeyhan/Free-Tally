import SwiftUI

/// A labeled control pairing a typed `TextField` with a `Stepper`, both bound to the
/// same `Int` value, so either typing a number or tapping +/- keeps the other in sync.
///
/// The keyboard is always `.numberPad` (digits only). For fields that need negative
/// values, a separate sign-toggle button flips the sign rather than using
/// `.numbersAndPunctuation`, which exposes a whole page of unrelated punctuation for
/// one minus key in what's meant to be a compact Form row.
struct NumericInputField: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...1000
    var stepAmount: Int = 1
    var allowsNegative: Bool = false

    @State private var digitsText: String = ""
    @State private var isNegative: Bool = false
    @FocusState private var isFocused: Bool

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
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isNegative ? "Negative" : "Positive")
            }

            TextField("0", text: $digitsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 60)
                .focused($isFocused)
                .onChange(of: digitsText) { _, newValue in
                    let filtered = newValue.filter(\.isNumber)
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
