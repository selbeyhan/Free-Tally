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

    var keepScreenAwake: Bool {
        didSet { UserDefaults.standard.set(keepScreenAwake, forKey: Keys.keepScreenAwake) }
    }

    private enum Keys {
        static let useVolumeButtons = "settings.useVolumeButtons"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let keepScreenAwake = "settings.keepScreenAwake"
    }

    init(defaults: UserDefaults = .standard) {
        useVolumeButtons = defaults.object(forKey: Keys.useVolumeButtons) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) as? Bool ?? true
        keepScreenAwake = defaults.object(forKey: Keys.keepScreenAwake) as? Bool ?? false
    }
}
