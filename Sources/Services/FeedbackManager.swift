import AudioToolbox

/// How pronounced a feedback pulse should be.
enum FeedbackLength: String, Codable, CaseIterable, Identifiable, Hashable {
    case short
    case long

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .short: "Short"
        case .long: "Long"
        }
    }
}

/// Drives both haptic and audible feedback for counter interactions.
///
/// VIBRATION: `UIImpactFeedbackGenerator` / SwiftUI's `.sensoryFeedback` (both Core
/// Haptics-backed) produced zero feedback on-device (iPhone 16 Pro, iOS 27), confirmed
/// with a fully isolated test. The only mechanism that reliably worked is
/// `AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)` — a fixed, non-parameterized
/// buzz with no API to vary duration or intensity directly. "Short" vs "long" is
/// therefore simulated by firing that fixed buzz multiple times in quick succession.
/// Raw `CHHapticEngine` (lower-level than the wrappers that failed) hasn't been tested
/// and might support real custom-duration haptics — worth trying later, not depended on
/// here given how long the haptics debugging already took to land on something working.
///
/// SOUND: uses `AudioServicesPlaySystemSound` with built-in iOS system sound IDs.
/// Unlike vibration, there are real distinct system sounds to choose from, so "short"
/// vs "long" uses two different IDs rather than repeating one (repeating a click would
/// sound like rapid clicking, not one longer sound). These play on the ringer/alert
/// audio channel, so they're silenced by the physical ring/silent switch and follow
/// ringer volume — that's inherent to the API, not a bug.
enum FeedbackManager {
    // MARK: Vibration

    private static let vibrateRepeatDelay: TimeInterval = 0.18
    private static let vibrateRepeats: [FeedbackLength: Int] = [.short: 1, .long: 3]

    /// Guards against overlapping repeat sequences when tapping rapidly with "Long"
    /// selected. Only ever read/written from the main thread (all call sites are
    /// main-thread UI actions), including the reset at the end of the background
    /// repeat sequence, so there's no cross-thread race on this flag.
    private static var isVibrating = false

    static func vibrate(enabled: Bool, length: FeedbackLength) {
        guard enabled else { return }
        let repeats = vibrateRepeats[length] ?? 1
        guard repeats > 1 else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            return
        }
        guard !isVibrating else { return }
        isVibrating = true
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<repeats {
                if i > 0 { Thread.sleep(forTimeInterval: vibrateRepeatDelay) }
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            DispatchQueue.main.async {
                isVibrating = false
            }
        }
    }

    // MARK: Sound

    // Community-catalogued built-in system sound IDs (no public Apple lookup API;
    // verified against github.com/TUNER88/iOSSystemSoundsLibrary):
    //   1104 = Tock.caf ("KeyPressed") — the standard iOS keyboard-tap click. Short,
    //          light, unmistakably a plain UI sound rather than an alert tone.
    //   1111 = jbl_confirm.caf ("JBL_Confirm") — a short multi-tone confirmation cue.
    //          Noticeably longer/richer than Tock while still brief, without sounding
    //          like an incoming-message alert.
    private static let soundIDs: [FeedbackLength: SystemSoundID] = [.short: 1104, .long: 1111]

    static func playSound(enabled: Bool, length: FeedbackLength) {
        guard enabled, let soundID = soundIDs[length] else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}
