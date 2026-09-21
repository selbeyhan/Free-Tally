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

    /// How long `kSystemSoundID_Vibrate` stays "busy" after firing, silently ignoring
    /// further calls (Apple's own docs: it "returns immediately and ignores other
    /// calls while playing"). This is a real OS-level limit, not something tunable via
    /// the call itself — this value is our own estimate of when it clears, genuinely
    /// unverified without on-device testing. First thing to tune: raise it if Short
    /// still drops occasionally, lower it if repeat taps start to feel delayed.
    private static let vibrateBusyWindow: TimeInterval = 0.15

    /// Only ever read/written from the main thread — the guard check happens from
    /// main-thread UI call sites, and the reset + retry happens inside a
    /// `DispatchQueue.main.asyncAfter` callback — so there's no cross-thread race on
    /// either flag below.
    private static var isVibrating = false

    /// Set when a vibration request arrives while one is already in flight. Coalesces
    /// any number of requests that pile up during the busy window into exactly one
    /// catch-up buzz once it clears, rather than dropping them (the previous behavior,
    /// and the whole reason "Short" felt like it skipped taps) or queuing each one
    /// individually (which would turn a fast burst into a trailing queue of buzzes
    /// playing out after the user has already stopped tapping).
    private static var hasPendingRetry = false

    static func vibrate(enabled: Bool, length: FeedbackLength) {
        guard enabled else { return }
        guard !isVibrating else {
            hasPendingRetry = true
            return
        }
        performVibration(length: length)
    }

    private static func performVibration(length: FeedbackLength) {
        isVibrating = true
        let repeats = vibrateRepeats[length] ?? 1
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<repeats {
                if i > 0 { Thread.sleep(forTimeInterval: vibrateRepeatDelay) }
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + vibrateBusyWindow) {
                isVibrating = false
                if hasPendingRetry {
                    hasPendingRetry = false
                    performVibration(length: length)
                }
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
