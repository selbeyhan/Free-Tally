import Foundation
import Observation

/// App-wide preferences. Backed by UserDefaults only — never synced anywhere.
@Observable
final class AppSettings {
    var useVolumeButtons: Bool {
        didSet { UserDefaults.standard.set(useVolumeButtons, forKey: Keys.useVolumeButtons) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var hapticLength: FeedbackLength {
        didSet { UserDefaults.standard.set(hapticLength.rawValue, forKey: Keys.hapticLength) }
    }

    var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    var soundLength: FeedbackLength {
        didSet { UserDefaults.standard.set(soundLength.rawValue, forKey: Keys.soundLength) }
    }

    var keepScreenAwake: Bool {
        didSet { UserDefaults.standard.set(keepScreenAwake, forKey: Keys.keepScreenAwake) }
    }

    private enum Keys {
        static let useVolumeButtons = "settings.useVolumeButtons"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let hapticLength = "settings.hapticLength"
        static let soundEnabled = "settings.soundEnabled"
        static let soundLength = "settings.soundLength"
        static let keepScreenAwake = "settings.keepScreenAwake"
    }

    init(defaults: UserDefaults = .standard) {
        useVolumeButtons = defaults.object(forKey: Keys.useVolumeButtons) as? Bool ?? false
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        hapticLength = defaults.string(forKey: Keys.hapticLength)
            .flatMap(FeedbackLength.init(rawValue:)) ?? .short
        soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? false
        soundLength = defaults.string(forKey: Keys.soundLength)
            .flatMap(FeedbackLength.init(rawValue:)) ?? .short
        keepScreenAwake = defaults.object(forKey: Keys.keepScreenAwake) as? Bool ?? false
    }
}
