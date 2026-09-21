import SwiftUI

/// A labeled control pairing a typed input with a `Stepper`, both bound to the same
/// `Int` value, so either typing a number or tapping +/- keeps the other in sync.
///
/// Fields that never need negative values (`allowsNegative == false`, e.g. step size)
/// use a plain `.numberPad`-backed `TextField`. Fields that do allow negatives
/// (`allowsNegative == true`, e.g. count) can't use the system numeric keyboard for
/// entry, because `UIKeyboardType` has no numeric-pad variant with a minus key in a
/// predictable spot — `.numbersAndPunctuation` opens a whole separate punctuation page
/// for one key. Instead those fields show a tappable value chip that expands an inline
/// custom keypad (digits 1-9, 0, and a dedicated negative-sign key at bottom-left,
/// matching a standard phone-keypad layout) directly in the Form row.
struct NumericInputField: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...1000
    var stepAmount: Int = 1
    var allowsNegative: Bool = false

    @State private var digitsText: String = ""
    @State private var isNegative: Bool = false
    @State private var isKeypadExpanded: Bool = false
    @FocusState private var isFocused: Bool

    private enum KeypadKey: Hashable {
        case digit(Int)
        case negative
        case delete
    }

    private static let keypadRows: [[KeypadKey]] = [
        [.digit(7), .digit(8), .digit(9)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(1), .digit(2), .digit(3)],
        [.negative, .digit(0), .delete]
    ]

    /// Caps how many digits `digitsText` can hold so it can't grow past what `Int` can
    /// parse (an all-digit string longer than ~19 characters makes `Int(_:)` return
    /// `nil`, which `recomputeValue()` would silently read as a magnitude of 0). Sized
    /// to the longest bound of `range`, so it's never smaller than a legitimate value.
    private var maxDigitCount: Int {
        String(max(abs(range.lowerBound), abs(range.upperBound))).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(title)

                Spacer()

                if allowsNegative {
                    Button {
                        withAnimation(.snappy) { isKeypadExpanded.toggle() }
                    } label: {
                        Text("\(value)")
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 60)
                    .valueChipStyle()
                    .accessibilityLabel("\(title) value")
                    .accessibilityValue("\(value)")
                    .accessibilityHint("Double tap to open the number pad")
                    .accessibilityAddTraits(isKeypadExpanded ? .isSelected : [])
                } else {
                    TextField("0", text: $digitsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60)
                        .valueChipStyle()
                        .focused($isFocused)
                        .onChange(of: digitsText) { _, newValue in
                            var filtered = newValue.filter(\.isNumber)
                            if filtered.count > maxDigitCount {
                                filtered = String(filtered.prefix(maxDigitCount))
                            }
                            if filtered != newValue { digitsText = filtered }
                            recomputeValue()
                        }
                }

                Stepper("", value: $value, in: range, step: stepAmount)
                    .labelsHidden()
            }

            if allowsNegative && isKeypadExpanded {
                keypad
            }
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

    private var keypad: some View {
        VStack(spacing: 8) {
            ForEach(Self.keypadRows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key)
                    }
                }
            }
        }
        .padding(.top, 2)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func keypadButton(_ key: KeypadKey) -> some View {
        Button {
            handleKeypadTap(key)
        } label: {
            keypadLabel(key)
                .font(.title3.weight(.medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func keypadLabel(_ key: KeypadKey) -> some View {
        switch key {
        case .digit(let digit):
            Text("\(digit)")
        case .negative:
            Image(systemName: "minus")
                .accessibilityLabel("Negative sign")
        case .delete:
            Image(systemName: "delete.left")
                .accessibilityLabel("Delete")
        }
    }

    private func handleKeypadTap(_ key: KeypadKey) {
        switch key {
        case .digit(let digit):
            guard digitsText.count < maxDigitCount else { return }
            digitsText.append(String(digit))
        case .negative:
            isNegative.toggle()
        case .delete:
            if !digitsText.isEmpty { digitsText.removeLast() }
        }
        recomputeValue()
    }

    private func recomputeValue() {
        let magnitude = Int(digitsText) ?? 0
        let signed = (allowsNegative && isNegative) ? -magnitude : magnitude
        value = min(max(signed, range.lowerBound), range.upperBound)
    }
}

private extension View {
    /// The rounded "chip" background shared by every tappable/editable value box in
    /// this field, so the Step field's `TextField` and the Count field's keypad
    /// trigger read as the same kind of control.
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
