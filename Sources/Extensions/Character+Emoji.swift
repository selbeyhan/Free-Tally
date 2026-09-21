import Foundation

/// Detects whether a `Character` is an emoji. Deliberately more careful than checking
/// the Unicode `isEmoji` property alone, which (for legacy keycap-sequence reasons)
/// also flags plain digits, `#`, and `*` as `true`. `Character` is grapheme-cluster
/// based, so this also correctly handles multi-scalar emoji — skin-tone modifiers,
/// ZWJ family sequences, and flags — as a single unit.
extension Character {
    var isSimpleEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && (firstScalar.value > 0x238C || unicodeScalars.count > 1)
    }

    var isCombinedIntoEmoji: Bool {
        unicodeScalars.count > 1 && unicodeScalars.contains { $0.properties.isJoinControl || $0.properties.isVariationSelector }
    }

    var isEmoji: Bool { isSimpleEmoji || isCombinedIntoEmoji }
}
