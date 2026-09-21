import SwiftUI
import UIKit

/// A single-emoji text field that opens directly to the system emoji keyboard (no
/// manual tap of the globe key) and only accepts emoji characters — everything else
/// typed or pasted is rejected outright. Always holds either exactly one emoji
/// `Character` or an empty string, matching `Counter.symbolName`'s single-emoji
/// contract: typing a new valid emoji replaces whatever's currently in the field
/// rather than appending to it.
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> EmojiKeyboardTextField {
        let textField = EmojiKeyboardTextField()
        textField.delegate = context.coordinator
        textField.text = text
        textField.placeholder = placeholder
        textField.font = .preferredFont(forTextStyle: .title3)
        textField.textAlignment = .right
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.autocapitalizationType = .none
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        return textField
    }

    func updateUIView(_ uiView: EmojiKeyboardTextField, context: Context) {
        // Keep the coordinator's binding reference current — EditCounterView's body
        // (and therefore its $customEmojiText Binding instance) is re-created on every
        // SwiftUI update pass, even though the underlying @State storage is stable.
        context.coordinator.text = $text

        // Only push into the UIKit field when it actually differs. The delegate below
        // already keeps `uiView.text` and `text` in lockstep on every keystroke, so in
        // the common case this is a no-op — critical, since assigning `.text`
        // unconditionally on every render would reset the cursor/selection on every
        // SwiftUI re-render, fighting live edits.
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.placeholder != placeholder {
            uiView.placeholder = placeholder
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Always allow deletion/clearing.
            guard !string.isEmpty else {
                textField.text = ""
                text.wrappedValue = ""
                return false
            }

            // Reject the whole edit if any character in it isn't emoji — no partial
            // acceptance of a mixed paste.
            guard string.allSatisfy(\.isEmoji), let newEmoji = string.last.map(String.init) else {
                return false
            }

            // Replace the field's entire contents with just the newly typed/pasted
            // emoji (taking `.last` handles a multi-emoji paste), rather than
            // inserting at `range`. Mutating `textField.text` directly and returning
            // `false` bypasses UIKit's normal insert-at-selection behavior, so the
            // field can never transiently show more than one emoji.
            textField.text = newEmoji
            text.wrappedValue = newEmoji

            let end = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: end, to: end)

            return false
        }
    }
}

/// `UITextField` subclass that forces the emoji keyboard open immediately, without
/// requiring a manual tap of the globe key.
private final class EmojiKeyboardTextField: UITextField {
    /// Search the currently active input modes for the emoji keyboard and force it as
    /// this field's preferred input mode. Without this override, the field opens to
    /// whichever keyboard was last active.
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
    }

    /// A stable, non-nil context identifier. iOS remembers the last-used keyboard per
    /// input context and can silently override the forced `textInputMode` on
    /// reappearance without this — pinning the identifier keeps the override reliable
    /// across refocus.
    override var textInputContextIdentifier: String? { "" }
}
