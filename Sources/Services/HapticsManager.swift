import AudioToolbox

/// Fires a short vibration using AudioServicesPlaySystemSound(kSystemSoundID_Vibrate).
///
/// This app originally used UIImpactFeedbackGenerator (SwiftUI's `sensoryFeedback`
/// modifier and raw UIKit both went through it), which is the modern, normally-preferred
/// Core Haptics-backed API. On-device testing (iPhone 16 Pro, iOS 27) showed it produces
/// no feedback at all — confirmed with a bare, fully isolated UIImpactFeedbackGenerator
/// call with no other code involved — while this older AudioToolbox-based path, a
/// completely separate subsystem, works reliably. So this is what actually drives the
/// app's haptic feedback, not a stopgap.
enum HapticsManager {
    static func tap(enabled: Bool) {
        guard enabled else { return }
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
