import UIKit

/// Thin wrapper around UIKit's feedback generators so views don't touch UIKit directly.
///
/// Generators are kept alive as prepared singletons rather than created fresh per tap.
/// Spinning up a brand-new `UIImpactFeedbackGenerator` and firing it in the same instant
/// doesn't give the Taptic Engine time to actually warm up, which can make feedback feel
/// weak or go missing under rapid repeated taps — exactly the pattern a tally counter
/// produces. Keeping one instance around and re-`prepare()`-ing right after each fire
/// keeps the engine warm for the next tap.
enum HapticsManager {
    private static let impactGenerator: UIImpactFeedbackGenerator = {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        return generator
    }()

    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func tap(enabled: Bool) {
        guard enabled else { return }
        impactGenerator.impactOccurred()
        impactGenerator.prepare()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
}
