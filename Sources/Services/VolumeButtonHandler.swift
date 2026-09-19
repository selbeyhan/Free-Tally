import AVFoundation
import MediaPlayer
import UIKit

/// Detects hardware volume button presses without letting the system volume actually
/// move (and without showing the system volume HUD).
///
/// The technique: activate an ambient `AVAudioSession`, park an invisible `MPVolumeView`
/// in the key window (its presence is what silences the system volume HUD), and observe
/// `outputVolume` via KVO. Every physical button press changes `outputVolume` by one
/// step, which fires the KVO callback.
///
/// We deliberately do *not* recenter the volume after every single press. Snapping the
/// slider back to 0.5 forces an extra programmatic volume change that itself takes a
/// beat to land, and a hardware press that arrives before it lands can get swallowed —
/// which is what "have to wait before it registers again" looks like. Instead we only
/// recenter once the volume drifts near an edge (close to 0.0 or 1.0, where the next
/// same-direction press would otherwise clamp and stop producing changes), so a burst of
/// same-direction presses fires back-to-back off real hardware steps.
///
/// This only works while the handler is `start()`-ed and the app is in the foreground.
final class VolumeButtonHandler: NSObject {
    var onVolumeButtonPressed: (() -> Void)?

    private let audioSession = AVAudioSession.sharedInstance()
    private weak var volumeSlider: UISlider?
    private var hiddenVolumeView: MPVolumeView?
    private var isObserving = false
    private var suppressNextChange = false
    private var lastTriggerDate = Date.distantPast

    private static let targetVolume: Float = 0.5
    private static let lowEdge: Float = 0.15
    private static let highEdge: Float = 0.85
    private static let debounceInterval: TimeInterval = 0.05

    func start() {
        guard !isObserving else { return }

        do {
            try audioSession.setCategory(.ambient, options: [.mixWithOthers])
            try audioSession.setActive(true, options: [])
        } catch {
            #if DEBUG
            print("VolumeButtonHandler: failed to activate audio session: \(error)")
            #endif
        }

        installHiddenVolumeViewIfNeeded()
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: [.new], context: nil)
        isObserving = true

        // The MPVolumeView's internal slider isn't populated the instant the view is
        // added to the hierarchy, so give it a beat before centering the volume.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.centerSystemVolume()
        }
    }

    func stop() {
        guard isObserving else { return }
        audioSession.removeObserver(self, forKeyPath: "outputVolume")
        isObserving = false
        hiddenVolumeView?.removeFromSuperview()
        hiddenVolumeView = nil
        volumeSlider = nil
        try? audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func installHiddenVolumeViewIfNeeded() {
        guard hiddenVolumeView == nil else { return }
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        else { return }

        let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        view.alpha = 0.0001
        view.isUserInteractionEnabled = false
        window.addSubview(view)
        hiddenVolumeView = view
        volumeSlider = view.subviews.compactMap { $0 as? UISlider }.first
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "outputVolume" else { return }

        if suppressNextChange {
            suppressNextChange = false
            return
        }

        let now = Date()
        guard now.timeIntervalSince(lastTriggerDate) > Self.debounceInterval else { return }
        lastTriggerDate = now

        let callback = onVolumeButtonPressed
        DispatchQueue.main.async {
            callback?()
        }

        let currentVolume = audioSession.outputVolume
        if currentVolume < Self.lowEdge || currentVolume > Self.highEdge {
            centerSystemVolume()
        }
    }

    private func centerSystemVolume() {
        suppressNextChange = true
        if volumeSlider == nil {
            volumeSlider = hiddenVolumeView?.subviews.compactMap { $0 as? UISlider }.first
        }
        volumeSlider?.setValue(Self.targetVolume, animated: false)
    }

    deinit {
        if isObserving {
            audioSession.removeObserver(self, forKeyPath: "outputVolume")
        }
    }
}
